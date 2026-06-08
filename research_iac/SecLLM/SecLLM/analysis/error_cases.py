"""
Script to analyze prediction errors in security smell detection with root cause analysis.
Produces structured output suitable for academic paper integration.
"""

import argparse
import json
import pandas as pd
from pathlib import Path
from typing import List, Dict, Tuple, Optional
import os
from openai import OpenAI
from collections import defaultdict, Counter
import difflib

# OpenAI configuration
client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

# Define error pattern categories
ERROR_CATEGORIES = {
    "VARIABLE_INDIRECTION": "Variable Indirection Ambiguity",
    "SMELL_OVERLAP": "Overlap with Other Smells", 
    "CONTEXT_DEPENDENT": "Context-Dependent String Literals",
    "COMPLEX_STRUCTURES": "Complex Data Structures",
    "CONDITIONAL_LOGIC": "Conditional Logic",
    "CROSS_FILE": "Cross-File Dependencies",
    "EXHAUSTIVE_ENUMERATION": "Exhaustive Enumeration",
    "PATTERN_MATCHING": "Exact Pattern Matching",
    "OTHER": "Other"
}

def parse_arguments():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Analyze prediction errors with root cause analysis"
    )
    parser.add_argument(
        "--predictions",
        type=str,
        required=True,
        help="Path to predictions JSON file"
    )
    parser.add_argument(
        "--oracle",
        type=str,
        required=True,
        help="Path to oracle CSV file"
    )
    parser.add_argument(
        "--technology",
        type=str,
        required=True,
        choices=["ansible", "chef", "puppet"],
        help="IaC technology (ansible, chef, puppet)"
    )
    parser.add_argument(
        "--model-name",
        type=str,
        default="Unknown",
        help="Name of the LLM model being analyzed"
    )
    parser.add_argument(
        "--use-gpt",
        action="store_true",
        help="Use GPT-4o for deep error analysis"
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default="error_analysis",
        help="Directory for output files"
    )
    parser.add_argument(
        "--max-gpt-per-smell",
        type=int,
        default=5,
        help="Maximum number of examples to analyze with GPT per smell"
    )
    parser.add_argument(
        "--dataset-base",
        type=str,
        default="../glitch-datasets",
        help="Base path for dataset files"
    )
    
    return parser.parse_args()

def normalize_filename(path: str) -> str:
    """Normalize filename by removing path prefixes."""
    return os.path.basename(path)

def find_script_file(filename: str, technology: str, dataset_base: str) -> Optional[str]:
    """Find the actual script file, trying multiple locations."""
    if technology == "chef":
        path ="../glitch-datasets/chef/oracle-dataset/recipes/"+filename
    else:
        path = f"../glitch-datasets/{technology}/oracle-dataset/{filename}"

    return path

def load_predictions(json_path: str) -> pd.DataFrame:
    """Load predictions from JSON file."""
    with open(json_path, 'r') as f:
        data = json.load(f)
    
    records = []
    if isinstance(data, dict):
        data = [data]
    
    for item in data:
        path = item.get("PATH", "")
        line = item.get("LINE", "-1")
        smell = item.get("SMELL", "none")
        
        if isinstance(line, str):
            line = line.strip()
            try:
                line = int(line)
            except ValueError:
                line = -1
        
        records.append({
            "PATH": path,
            "LINE": line,
            "SMELL": smell
        })
    
    df = pd.DataFrame(records)
    df = df.drop_duplicates(subset=['PATH', 'LINE', 'SMELL'])
    
    print(f"  Loaded {len(df)} predictions")
    print(f"  Smell distribution: {df['SMELL'].value_counts().to_dict()}")
    
    return df

def load_oracle(csv_path: str) -> pd.DataFrame:
    """Load oracle from CSV file."""
    try:
        df = pd.read_csv(csv_path, sep=",")
    except:
        try:
            df = pd.read_csv(csv_path, sep=";")
        except:
            df = pd.read_csv(csv_path, sep="\t")
    
    column_mapping = {}
    for col in df.columns:
        col_upper = col.strip().upper()
        if 'PATH' in col_upper or 'FILE' in col_upper:
            column_mapping[col] = 'PATH'
        elif 'LINE' in col_upper:
            column_mapping[col] = 'LINE'
        elif 'CATEGORY' in col_upper or 'SMELL' in col_upper:
            column_mapping[col] = 'CATEGORY'
    
    df = df.rename(columns=column_mapping)
    
    if 'LINE' in df.columns:
        df['LINE'] = pd.to_numeric(df['LINE'], errors='coerce').fillna(-1).astype(int)
    
    print(f"  Loaded {len(df)} oracle entries")
    print(f"  Category distribution: {df['CATEGORY'].value_counts().to_dict()}")
    
    return df

def build_comparison_dataset(
    predictions_df: pd.DataFrame,
    oracle_df: pd.DataFrame
) -> pd.DataFrame:
    """Build comparison dataset between predictions and oracle."""
    result = []
    
    predictions_df = predictions_df.copy()
    oracle_df = oracle_df.copy()
    predictions_df['PATH_NORM'] = predictions_df['PATH'].apply(normalize_filename)
    oracle_df['PATH_NORM'] = oracle_df['PATH'].apply(normalize_filename)
    
    # Find matches and false negatives
    for _, row in oracle_df.iterrows():
        path_norm = row["PATH_NORM"]
        line = row["LINE"]
        category = row["CATEGORY"]
        
        if category == 'none':
            continue
        
        match = predictions_df[
            (predictions_df["PATH_NORM"] == path_norm) & 
            (predictions_df["LINE"] == line) & 
            (predictions_df["SMELL"] == category)
        ]
        
        if not match.empty:
            result.append({
                "PATH": row["PATH"],
                "LINE": line,
                "SMELL": category,
                "CATEGORY": category,
                "TYPE": "TP"
            })
        else:
            result.append({
                "PATH": row["PATH"],
                "LINE": line,
                "SMELL": "none",
                "CATEGORY": category,
                "TYPE": "FN"
            })
    
    # Find false positives
    for _, row in predictions_df.iterrows():
        path_norm = row["PATH_NORM"]
        line = row["LINE"]
        smell = row["SMELL"]
        
        if smell == 'none':
            continue
        
        match_in_result = next(
            (r for r in result 
             if normalize_filename(r["PATH"]) == path_norm 
             and r["LINE"] == line 
             and r["SMELL"] == smell),
            None
        )
        
        if not match_in_result:
            oracle_entry = oracle_df[
                (oracle_df["PATH_NORM"] == path_norm) & 
                (oracle_df["LINE"] == line)
            ]
            
            if not oracle_entry.empty:
                actual_category = oracle_entry.iloc[0]["CATEGORY"]
            else:
                actual_category = "none"
            
            result.append({
                "PATH": row["PATH"],
                "LINE": line,
                "SMELL": smell,
                "CATEGORY": actual_category,
                "TYPE": "FP"
            })
    
    df = pd.DataFrame(result)
    print(f"\n  Comparison breakdown: TP={len(df[df['TYPE']=='TP'])}, "
          f"FP={len(df[df['TYPE']=='FP'])}, FN={len(df[df['TYPE']=='FN'])}")
    
    return df

def read_script_content(filepath: str) -> Tuple[str, bool]:
    """Read script content and return content + success flag."""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            return content, True
    except Exception as e:
        return f"[Error reading file: {e}]", False

def extract_code_context(content: str, line_number: int, context_lines: int = 7) -> Tuple[str, str]:
    """
    Extract code context around a specific line.
    Returns (context_with_markers, actual_line_content)
    """
    lines = content.split('\n')
    
    if line_number < 1 or line_number > len(lines):
        return "[Invalid line number]", "[No content]"
    
    actual_line = lines[line_number - 1]
    
    start = max(0, line_number - context_lines - 1)
    end = min(len(lines), line_number + context_lines)
    
    context = []
    for i in range(start, end):
        marker = ">>> " if i == line_number - 1 else "    "
        context.append(f"{marker}{i+1:4d}: {lines[i]}")
    
    return "\n".join(context), actual_line

def analyze_with_gpt(
    script_content: str,
    line_number: int,
    actual_line: str,
    smell_type: str,
    error_type: str,
    technology: str,
    actual_category: str = None
) -> Dict:
    """Use GPT-4o to analyze a specific error and categorize it."""
    
    context, _ = extract_code_context(script_content, line_number, context_lines=10)
    
    categories_list = "\n".join([f"   - {v}" for v in ERROR_CATEGORIES.values()])
    
    if error_type == "FP":
        error_desc = f"SecLLM incorrectly detected '{smell_type}' at this line, but the oracle says it's '{actual_category}'"
    else:  # FN
        error_desc = f"SecLLM failed to detect '{smell_type}' at this line (predicted 'none')"
    
    prompt = f"""You are a security expert analyzing why an LLM-based security smell detector made an error in analyzing Infrastructure as Code scripts.

**Context:**
- IaC Technology: {technology}
- Error Type: {error_type} (False Positive or False Negative)
- {error_desc}

**The Actual Line (#{line_number}):**
```
{actual_line}
```

**Surrounding Code Context:**
```
{context}
```

**Available Root Cause Categories:**
{categories_list}

**Task:**
Analyze why this error occurred by examining the actual code. Provide:

1. **Root Cause** (2-3 sentences): Look at the actual code at line {line_number} and explain specifically why the detector made this error. What pattern or context led to the misclassification?

2. **Error Category** (select ONE from the list above): Which category best describes this specific error?

3. **Code Pattern** (1 sentence): Describe the specific code pattern at this line that caused confusion.

4. **Improvement Suggestion** (1-2 sentences): How could the detector's prompts or logic be improved to handle this specific pattern correctly?

**Important:** Base your analysis on the ACTUAL code shown, not on hypothetical scenarios.

Respond in JSON format:
{{
    "root_cause": "...",
    "category": "...",
    "code_pattern": "...",
    "improvement": "..."
}}
"""

    try:
        response = client.chat.completions.create(
            model="gpt-4o",
            messages=[
                {"role": "system", "content": "You are an expert in Infrastructure as Code security analysis. Always respond with valid JSON. Analyze the actual code provided."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.2,
            max_tokens=500,
            response_format={"type": "json_object"}
        )
        
        result = json.loads(response.choices[0].message.content)
        return result
    except Exception as e:
        return {
            "root_cause": f"[Error in GPT analysis: {e}]",
            "category": "OTHER",
            "code_pattern": "Analysis failed",
            "improvement": "N/A"
        }

def aggregate_error_patterns(analyses: List[Dict]) -> Dict:
    """Aggregate multiple GPT analyses to find common patterns."""
    categories = Counter()
    patterns = []
    root_causes = []
    improvements = []
    
    for analysis in analyses:
        if analysis and "category" in analysis:
            categories[analysis["category"]] += 1
            patterns.append(analysis.get("code_pattern", ""))
            root_causes.append(analysis.get("root_cause", ""))
            improvements.append(analysis.get("improvement", ""))
    
    return {
        "dominant_category": categories.most_common(1)[0][0] if categories else "OTHER",
        "category_distribution": dict(categories),
        "sample_patterns": [p for p in patterns if p and p != "Analysis failed"][:3],
        "sample_root_causes": [r for r in root_causes if r and not r.startswith("[Error")][:3],
        "sample_improvements": [i for i in improvements if i and i != "N/A"][:3]
    }

def analyze_error_group(
    error_df: pd.DataFrame,
    smell: str,
    error_type: str,
    technology: str,
    dataset_base: str,
    use_gpt: bool,
    max_gpt_analyses: int
) -> Dict:
    """Analyze a group of errors for a specific smell."""
    
    print(f"\n  Analyzing {smell} ({len(error_df)} cases)...")
    
    result = {
        "smell": smell,
        "error_type": error_type,
        "count": len(error_df),
        "examples": [],
        "gpt_analyses": [],
        "file_issues": []
    }
    
    # Collect examples with validation
    valid_examples = []
    for idx, (_, row) in enumerate(error_df.head(20).iterrows()):
        filepath = find_script_file(row["PATH"], technology, dataset_base)
        
        if filepath and os.path.exists(filepath):
            content, success = read_script_content(filepath)
            if success:
                context, actual_line = extract_code_context(content, int(row["LINE"]))
                
                if actual_line != "[No content]":
                    valid_examples.append({
                        "file": row["PATH"],
                        "line": int(row["LINE"]),
                        "predicted": row["SMELL"],
                        "actual": row["CATEGORY"],
                        "filepath": filepath,
                        "actual_line": actual_line,
                        "content": content
                    })
        else:
            result["file_issues"].append({
                "file": row["PATH"],
                "line": int(row["LINE"]),
                "issue": f"File not found. Searched: {normalize_filename(row['PATH'])}"
            })
    
    result["examples"] = [{k: v for k, v in ex.items() if k not in ['content', 'filepath']} 
                          for ex in valid_examples[:10]]
    
    print(f"    Found {len(valid_examples)} valid examples (out of {len(error_df)})")
    
    # GPT analysis on valid examples only
    if use_gpt and len(valid_examples) > 0:
        sample_size = min(max_gpt_analyses, len(valid_examples))
        print(f"    Running GPT analysis on {sample_size} valid samples...")
        
        gpt_analyses = []
        for ex in valid_examples[:sample_size]:
            print(f"      Analyzing {os.path.basename(ex['file'])}:{ex['line']}... ", end="")
            
            analysis = analyze_with_gpt(
                ex['content'],
                ex['line'],
                ex['actual_line'],
                smell if error_type == "FN" else ex['predicted'],
                error_type,
                technology,
                ex['actual']
            )
            
            print("✓")
            
            gpt_analyses.append({
                "file": ex['file'],
                "line": ex['line'],
                "actual_line": ex['actual_line'],
                "analysis": analysis
            })
        
        result["gpt_analyses"] = gpt_analyses
        result["aggregated_patterns"] = aggregate_error_patterns([a["analysis"] for a in gpt_analyses])
    
    return result

def perform_root_cause_analysis(
    comparison_df: pd.DataFrame,
    technology: str,
    dataset_base: str,
    use_gpt: bool,
    max_gpt_per_smell: int
) -> Dict:
    """Perform comprehensive root cause analysis."""
    
    false_positives = comparison_df[comparison_df["TYPE"] == "FP"].copy()
    false_negatives = comparison_df[comparison_df["TYPE"] == "FN"].copy()
    true_positives = comparison_df[comparison_df["TYPE"] == "TP"].copy()
    
    # Statistics
    total_predictions = len(true_positives) + len(false_positives)
    total_actual = len(true_positives) + len(false_negatives)
    
    stats = {
        "true_positives": len(true_positives),
        "false_positives": len(false_positives),
        "false_negatives": len(false_negatives),
        "precision": len(true_positives) / total_predictions if total_predictions > 0 else 0,
        "recall": len(true_positives) / total_actual if total_actual > 0 else 0,
    }
    
    if stats["precision"] + stats["recall"] > 0:
        stats["f1_score"] = 2 * (stats["precision"] * stats["recall"]) / (stats["precision"] + stats["recall"])
    else:
        stats["f1_score"] = 0
    
    # Analyze false positives
    fp_analysis = []
    if len(false_positives) > 0:
        print(f"\n{'='*80}")
        print(f"ANALYZING FALSE POSITIVES ({len(false_positives)} total)")
        print(f"{'='*80}")
        
        for smell in sorted(false_positives["SMELL"].unique()):
            smell_fps = false_positives[false_positives["SMELL"] == smell]
            analysis = analyze_error_group(
                smell_fps, smell, "FP", technology, dataset_base, use_gpt, max_gpt_per_smell
            )
            fp_analysis.append(analysis)
    
    # Analyze false negatives
    fn_analysis = []
    if len(false_negatives) > 0:
        print(f"\n{'='*80}")
        print(f"ANALYZING FALSE NEGATIVES ({len(false_negatives)} total)")
        print(f"{'='*80}")
        
        for smell in sorted(false_negatives["CATEGORY"].unique()):
            smell_fns = false_negatives[false_negatives["CATEGORY"] == smell]
            analysis = analyze_error_group(
                smell_fns, smell, "FN", technology, dataset_base, use_gpt, max_gpt_per_smell
            )
            fn_analysis.append(analysis)
    
    return {
        "statistics": stats,
        "false_positive_analysis": fp_analysis,
        "false_negative_analysis": fn_analysis
    }

def generate_paper_sections(analysis: Dict, model_name: str, technology: str) -> str:
    """Generate formatted text sections for paper integration."""
    
    stats = analysis["statistics"]
    
    output = f"""
{'='*80}
ROOT CAUSE ANALYSIS FOR PAPER
Model: {model_name} | Technology: {technology}
{'='*80}

## PERFORMANCE METRICS

Precision: {stats['precision']:.4f}
Recall: {stats['recall']:.4f}
F1-Score: {stats['f1_score']:.4f}

True Positives: {stats['true_positives']}
False Positives: {stats['false_positives']}
False Negatives: {stats['false_negatives']}

"""
    
    # False Positives Section
    if analysis["false_positive_analysis"]:
        output += "\n## FALSE POSITIVES - ROOT CAUSE SUMMARY\n\n"
        
        for fp_group in analysis["false_positive_analysis"]:
            output += f"### {fp_group['smell']} ({fp_group['count']} cases)\n\n"
            
            if "aggregated_patterns" in fp_group:
                agg = fp_group["aggregated_patterns"]
                output += f"**Dominant Error Category:** {agg['dominant_category']}\n\n"
                
                if agg.get("sample_root_causes"):
                    output += "**Root Causes:**\n"
                    for i, cause in enumerate(agg["sample_root_causes"], 1):
                        output += f"{i}. {cause}\n"
                    output += "\n"
                
                if agg.get("sample_patterns"):
                    output += "**Code Patterns:**\n"
                    for i, pattern in enumerate(agg["sample_patterns"], 1):
                        output += f"{i}. {pattern}\n"
                    output += "\n"
                
                if agg.get("sample_improvements"):
                    output += "**Improvement Suggestions:**\n"
                    for i, imp in enumerate(agg["sample_improvements"], 1):
                        output += f"{i}. {imp}\n"
                    output += "\n"
            
            # Show concrete examples with actual code
            if fp_group.get("examples"):
                output += "**Concrete Examples:**\n"
                for i, ex in enumerate(fp_group["examples"][:3], 1):
                    output += f"{i}. File: {os.path.basename(ex['file'])}, Line: {ex['line']}\n"
                    output += f"   Predicted: {ex['predicted']}, Actual: {ex['actual']}\n"
                    if 'actual_line' in ex:
                        output += f"   Code: {ex['actual_line']}\n"
                output += "\n"
    
    # False Negatives Section
    if analysis["false_negative_analysis"]:
        output += "\n## FALSE NEGATIVES - ROOT CAUSE SUMMARY\n\n"
        
        for fn_group in analysis["false_negative_analysis"]:
            output += f"### {fn_group['smell']} ({fn_group['count']} cases)\n\n"
            
            if "aggregated_patterns" in fn_group:
                agg = fn_group["aggregated_patterns"]
                output += f"**Dominant Error Category:** {agg['dominant_category']}\n\n"
                
                if agg.get("sample_root_causes"):
                    output += "**Root Causes:**\n"
                    for i, cause in enumerate(agg["sample_root_causes"], 1):
                        output += f"{i}. {cause}\n"
                    output += "\n"
                
                if agg.get("sample_patterns"):
                    output += "**Code Patterns:**\n"
                    for i, pattern in enumerate(agg["sample_patterns"], 1):
                        output += f"{i}. {pattern}\n"
                    output += "\n"
                
                if agg.get("sample_improvements"):
                    output += "**Improvement Suggestions:**\n"
                    for i, imp in enumerate(agg["sample_improvements"], 1):
                        output += f"{i}. {imp}\n"
                    output += "\n"
            
            if fn_group.get("examples"):
                output += "**Concrete Examples:**\n"
                for i, ex in enumerate(fn_group["examples"][:3], 1):
                    output += f"{i}. File: {os.path.basename(ex['file'])}, Line: {ex['line']}\n"
                    output += f"   Predicted: {ex['predicted']}, Expected: {ex['actual']}\n"
                    if 'actual_line' in ex:
                        output += f"   Code: {ex['actual_line']}\n"
                output += "\n"
    
    # Summary
    output += "\n## OVERALL ERROR CATEGORY DISTRIBUTION\n\n"
    
    all_categories = Counter()
    for fp_group in analysis.get("false_positive_analysis", []):
        if "aggregated_patterns" in fp_group:
            for cat, count in fp_group["aggregated_patterns"]["category_distribution"].items():
                all_categories[cat] += count
    
    for fn_group in analysis.get("false_negative_analysis", []):
        if "aggregated_patterns" in fn_group:
            for cat, count in fn_group["aggregated_patterns"]["category_distribution"].items():
                all_categories[cat] += count
    
    if all_categories:
        for cat, count in all_categories.most_common():
            output += f"- {ERROR_CATEGORIES.get(cat, cat)}: {count} instances\n"
    
    output += f"\n{'='*80}\n"
    
    return output

def save_detailed_json(analysis: Dict, output_path: str):
    """Save detailed JSON for further processing."""
    with open(output_path, 'w') as f:
        json.dump(analysis, f, indent=2)
    print(f"  Detailed JSON saved to: {output_path}")

def main():
    """Main execution function."""
    args = parse_arguments()
    
    # Create output directory
    os.makedirs(args.output_dir, exist_ok=True)
    
    print(f"\n{'='*80}")
    print(f"ROOT CAUSE ANALYSIS")
    print(f"{'='*80}")
    print(f"Model: {args.model_name}")
    print(f"Technology: {args.technology}")
    print(f"Predictions: {args.predictions}")
    print(f"Oracle: {args.oracle}")
    print(f"Dataset base: {args.dataset_base}")
    print(f"Use GPT: {args.use_gpt}")
    print(f"{'='*80}\n")
    
    # Load data
    print("Loading predictions...")
    predictions_df = load_predictions(args.predictions)
    
    print("\nLoading oracle...")
    oracle_df = load_oracle(args.oracle)
    
    # Build comparison
    print("\nBuilding comparison dataset...")
    comparison_df = build_comparison_dataset(predictions_df, oracle_df)
    
    # Perform root cause analysis
    print("\nPerforming root cause analysis...")
    analysis = perform_root_cause_analysis(
        comparison_df,
        args.technology,
        args.dataset_base,
        args.use_gpt,
        args.max_gpt_per_smell
    )
    
    # Generate paper sections
    paper_text = generate_paper_sections(analysis, args.model_name, args.technology)
    print(paper_text)
    
    # Save outputs
    base_name = f"{args.model_name}_{args.technology}"
    
    # Save formatted text
    text_path = os.path.join(args.output_dir, f"{base_name}_paper_sections.txt")
    with open(text_path, 'w') as f:
        f.write(paper_text)
    print(f"\n✓ Paper sections saved to: {text_path}")
    
    # Save detailed JSON
    json_path = os.path.join(args.output_dir, f"{base_name}_detailed_analysis.json")
    save_detailed_json(analysis, json_path)
    
    print(f"\n✓ Analysis completed!")

if __name__ == "__main__":
    main()