import argparse
import pandas as pd
import numpy as np
from scipy.stats import ranksums
import json
import os
from pathlib import Path
import matplotlib.pyplot as plt
import seaborn as sns

def load_dataset(filename):
    """
    Load dataset from CSV or JSON file.
    
    Args:
        filename: Path to the dataset file
        
    Returns:
        pandas DataFrame containing the dataset
    """
    if filename.endswith("csv"):
        try:
            df = pd.read_csv(filename, sep=",")
        except Exception as e:
            df = pd.read_csv(filename, sep=";")
    else:
        df = pd.read_json(filename)
    return df

def match_predictions_with_ground_truth(smell_dataset, oracle_dataset):
    """
    Match predictions with ground truth data using two-pass logic.
    
    Args:
        smell_dataset: DataFrame with predictions
        oracle_dataset: DataFrame with ground truth
        
    Returns:
        DataFrame with matched results including confidence values
    """
    result = []
    
    # PRIMA ITERAZIONE: Process ground truth
    for _, row in oracle_dataset.iterrows():
        path, line, category = row["PATH"], row["LINE"], row["CATEGORY"]
        
        # Cerca predizione che matcha esattamente
        match = smell_dataset[
            (smell_dataset["PATH"] == path) & 
            (smell_dataset["LINE"] == line) & 
            (smell_dataset["SMELL"] == category)
        ]
        
        if not match.empty:
            # TRUE POSITIVE o TRUE NEGATIVE
            confidence = float(match.iloc[0]["CONFIDENCE"])
            result.append({
                "PATH": path,
                "LINE": int(line),
                "SMELL": category,
                "CATEGORY": category,
                "CONFIDENCE": confidence,
                "CORRECT": True,
                "TYPE": "TP" if category != "none" else "TN"
            })
        elif category != 'none':
            # FALSE NEGATIVE: smell nel GT ma non predetto
            # Verifica se c'è una predizione 'none' per questa posizione
            none_pred = smell_dataset[
                (smell_dataset["PATH"] == path) & 
                (smell_dataset["LINE"] == line) & 
                (smell_dataset["SMELL"] == "none")
            ]
            
            if not none_pred.empty:
                # Il modello ha esplicitamente predetto 'none'
                confidence = float(none_pred.iloc[0]["CONFIDENCE"])
            else:
                # Nessuna predizione per questa posizione
                confidence = None
            
            result.append({
                "PATH": path,
                "LINE": int(line),
                "SMELL": "none",
                "CATEGORY": category,
                "CONFIDENCE": confidence,
                "CORRECT": False,
                "TYPE": "FN"
            })
    
    # SECONDA ITERAZIONE: Process predictions not yet in result
    for _, row in smell_dataset.iterrows():
        path, line, smell = row["PATH"], row["LINE"], row["SMELL"]
        
        # Verifica se questa predizione è già in result
        match = next(
            (r for r in result 
             if r["PATH"] == path 
             and r["LINE"] == line 
             and r["SMELL"] == smell),
            None
        )
        
        if not match and smell != 'none':
            # FALSE POSITIVE: predetto smell non nel GT
            confidence = float(row["CONFIDENCE"])
            result.append({
                "PATH": path,
                "LINE": int(line),
                "SMELL": smell,
                "CATEGORY": "none",
                "CONFIDENCE": confidence,
                "CORRECT": False,
                "TYPE": "FP"
            })
        elif not match and smell == 'none':
            # TRUE NEGATIVE: correttamente predetto 'none'
            # Verifica nel GT se c'è effettivamente 'none'
            gt_none = oracle_dataset[
                (oracle_dataset["PATH"] == path) & 
                (oracle_dataset["LINE"] == line) & 
                (oracle_dataset["CATEGORY"] == "none")
            ]
            
            if not gt_none.empty:
                confidence = float(row["CONFIDENCE"])
                result.append({
                    "PATH": path,
                    "LINE": int(line),
                    "SMELL": "none",
                    "CATEGORY": "none",
                    "CONFIDENCE": confidence,
                    "CORRECT": True,
                    "TYPE": "TN"
                })
    
    return pd.DataFrame(result)


def compute_confidence_statistics(matched_df):
    """
    Compute statistics about confidence values per smell type.
    
    Args:
        matched_df: DataFrame with matched predictions
        
    Returns:
        Dictionary with statistics
    """
    stats = {}
    
    # Filter out None confidence values for overall statistics
    valid_conf_df = matched_df[matched_df['CONFIDENCE'].notna()]
    
    # Overall statistics
    stats['overall'] = {
        'mean': float(valid_conf_df['CONFIDENCE'].mean()),
        'median': float(valid_conf_df['CONFIDENCE'].median()),
        'std': float(valid_conf_df['CONFIDENCE'].std()),
        'min': float(valid_conf_df['CONFIDENCE'].min()),
        'max': float(valid_conf_df['CONFIDENCE'].max()),
        'count_with_confidence': int(len(valid_conf_df)),
        'count_without_confidence': int(matched_df['CONFIDENCE'].isna().sum())
    }

    
    # Statistics per smell type (category - ground truth)
    stats['per_smell'] = {}
    for smell in matched_df['CATEGORY'].unique():
        smell_data = matched_df[matched_df['CATEGORY'] == smell]
        valid_smell_data = smell_data[smell_data['CONFIDENCE'].notna()]
        
        # Overall smell statistics
        if len(valid_smell_data) > 0:
            stats['per_smell'][str(smell)] = {
                'mean': float(valid_smell_data['CONFIDENCE'].mean()),
                'median': float(valid_smell_data['CONFIDENCE'].median()),
                'std': float(valid_smell_data['CONFIDENCE'].std()),
                'count': int(len(smell_data)),
                'count_with_confidence': int(len(valid_smell_data)),
                'count_without_confidence': int(smell_data['CONFIDENCE'].isna().sum())
            }
        else:
            stats['per_smell'][str(smell)] = {
                'mean': None,
                'median': None,
                'std': None,
                'count': int(len(smell_data)),
                'count_with_confidence': 0,
                'count_without_confidence': int(len(smell_data))
            }
        
        # Add correct/incorrect breakdown for this smell type
        correct_smell_data = valid_smell_data[valid_smell_data['CORRECT'] == True]
        incorrect_smell_data = valid_smell_data[valid_smell_data['CORRECT'] == False]
        
        stats['per_smell'][str(smell)]['correct'] = {
            'mean': float(correct_smell_data['CONFIDENCE'].mean()) if len(correct_smell_data) > 0 else None,
            'median': float(correct_smell_data['CONFIDENCE'].median()) if len(correct_smell_data) > 0 else None,
            'std': float(correct_smell_data['CONFIDENCE'].std()) if len(correct_smell_data) > 0 else None,
            'count': int(len(correct_smell_data))
        }
        
        stats['per_smell'][str(smell)]['incorrect'] = {
            'mean': float(incorrect_smell_data['CONFIDENCE'].mean()) if len(incorrect_smell_data) > 0 else None,
            'median': float(incorrect_smell_data['CONFIDENCE'].median()) if len(incorrect_smell_data) > 0 else None,
            'std': float(incorrect_smell_data['CONFIDENCE'].std()) if len(incorrect_smell_data) > 0 else None,
            'count': int(len(incorrect_smell_data))
        }
    
    # Statistics for correct vs incorrect predictions
    correct_data = matched_df[matched_df['CORRECT'] == True]
    incorrect_data = matched_df[matched_df['CORRECT'] == False]
    
    valid_correct = correct_data[correct_data['CONFIDENCE'].notna()]
    valid_incorrect = incorrect_data[incorrect_data['CONFIDENCE'].notna()]
    
    stats['correct'] = {
        'mean': float(valid_correct['CONFIDENCE'].mean()) if len(valid_correct) > 0 else None,
        'median': float(valid_correct['CONFIDENCE'].median()) if len(valid_correct) > 0 else None,
        'std': float(valid_correct['CONFIDENCE'].std()) if len(valid_correct) > 0 else None,
        'count': int(len(correct_data)),
        'count_with_confidence': int(len(valid_correct))
    }
    
    stats['incorrect'] = {
        'mean': float(valid_incorrect['CONFIDENCE'].mean()) if len(valid_incorrect) > 0 else None,
        'median': float(valid_incorrect['CONFIDENCE'].median()) if len(valid_incorrect) > 0 else None,
        'std': float(valid_incorrect['CONFIDENCE'].std()) if len(valid_incorrect) > 0 else None,
        'count': int(len(incorrect_data)),
        'count_with_confidence': int(len(valid_incorrect))
    }
    
    return stats

def holm_bonferroni_correction(p_values, alpha=0.05):
    """
    Apply Holm-Bonferroni correction for multiple hypothesis testing.
    
    Args:
        p_values: List of p-values
        alpha: Significance level
        
    Returns:
        List of booleans indicating rejection and list of corrected p-values
    """
    n = len(p_values)
    if n == 0:
        return [], []
    
    # Sort p-values and keep track of original indices
    sorted_indices = np.argsort(p_values)
    sorted_p_values = np.array(p_values)[sorted_indices]
    
    # Apply Holm-Bonferroni correction
    reject = np.zeros(n, dtype=bool)
    corrected_p_values = np.zeros(n)
    
    for i in range(n):
        # Adjusted alpha for this test
        adjusted_alpha = alpha / (n - i)
        corrected_p_values[sorted_indices[i]] = min(sorted_p_values[i] * (n - i), 1.0)
        
        if sorted_p_values[i] <= adjusted_alpha:
            reject[sorted_indices[i]] = True
        else:
            # Once we fail to reject, all subsequent hypotheses are not rejected
            break
    
    return reject.tolist(), corrected_p_values.tolist()

def perform_wilcoxon_test(matched_df):
    """
    Perform Wilcoxon Rank-Sum Test to assess if confidence differs 
    between correct and incorrect predictions.
    Apply Holm-Bonferroni correction for multiple comparisons.
    
    Args:
        matched_df: DataFrame with matched predictions
        
    Returns:
        Dictionary with test results
    """
    results = {}
    
    # Filter out rows without confidence values
    valid_df = matched_df[matched_df['CONFIDENCE'].notna()]
    
    print("\n--- Wilcoxon Test Details ---")
    
    # Overall test
    correct_confidences = valid_df[valid_df['CORRECT'] == True]['CONFIDENCE']
    incorrect_confidences = valid_df[valid_df['CORRECT'] == False]['CONFIDENCE']
    
    print(f"\nOverall test:")
    print(f"  Correct predictions with confidence: {len(correct_confidences)}")
    print(f"  Incorrect predictions with confidence: {len(incorrect_confidences)}")
    
    if len(correct_confidences) > 0 and len(incorrect_confidences) > 0:
        statistic, p_value = ranksums(correct_confidences, incorrect_confidences, alternative='greater')
        results['overall'] = {
            'statistic': float(statistic),
            'p_value': float(p_value),
            'significant': bool(p_value < 0.05),
            'n_correct': int(len(correct_confidences)),
            'n_incorrect': int(len(incorrect_confidences))
        }
        print(f"  Test performed: statistic={statistic:.4f}, p-value={p_value:.6f}")
    else:
        print(f"  Test skipped: insufficient data")
    
    # Per-smell tests
    smell_tests = []
    smell_names = []
    
    print(f"\nPer-smell tests:")
    for smell in sorted(valid_df['CATEGORY'].unique()):
        if smell == 'none':
            continue
            
        smell_data = valid_df[valid_df['CATEGORY'] == smell]
        correct = smell_data[smell_data['CORRECT'] == True]['CONFIDENCE']
        incorrect = smell_data[smell_data['CORRECT'] == False]['CONFIDENCE']
        
        print(f"\n  {smell}:")
        print(f"    Correct: {len(correct)}, Incorrect: {len(incorrect)}")
        
        if len(correct) > 0 and len(incorrect) > 0:
            statistic, p_value = ranksums(correct, incorrect, alternative='greater')
            smell_tests.append(p_value)
            smell_names.append(str(smell))
            
            results[str(smell)] = {
                'statistic': float(statistic),
                'p_value': float(p_value),
                'n_correct': int(len(correct)),
                'n_incorrect': int(len(incorrect))
            }
            print(f"    Test performed: statistic={statistic:.4f}, p-value={p_value:.6f}")
        else:
            print(f"    Test skipped: insufficient data (need both correct and incorrect predictions)")
    
    # Apply Holm-Bonferroni correction
    if len(smell_tests) > 0:
        print(f"\nApplying Holm-Bonferroni correction to {len(smell_tests)} tests...")
        reject, pvals_corrected = holm_bonferroni_correction(smell_tests, alpha=0.05)
        
        for i, smell in enumerate(smell_names):
            results[smell]['p_value_corrected'] = float(pvals_corrected[i])
            results[smell]['significant_corrected'] = bool(reject[i])
            print(f"  {smell}: p_corrected={pvals_corrected[i]:.6f}, reject={reject[i]}")
    else:
        print(f"\nNo tests to correct (no smell had both correct and incorrect predictions)")
    
    print("--- End Wilcoxon Test Details ---\n")
    
    return results

def determine_confidence_thresholds(matched_df, precision_target=0.95):
    """
    Determine confidence thresholds for acceptable predictions.
    
    Args:
        matched_df: DataFrame with matched predictions
        precision_target: Target precision for high-confidence predictions
        
    Returns:
        Dictionary with threshold recommendations
    """
    # Filter out rows without confidence
    valid_df = matched_df[matched_df['CONFIDENCE'].notna()].copy()
    
    if len(valid_df) == 0:
        return {
            'thresholds': {},
            'recommendations': {},
            'confidence_stats': {}
        }
    
    # Confidence statistics
    confidence_stats = {
        'min': float(valid_df['CONFIDENCE'].min()),
        'max': float(valid_df['CONFIDENCE'].max()),
        'mean': float(valid_df['CONFIDENCE'].mean()),
        'median': float(valid_df['CONFIDENCE'].median()),
        'std': float(valid_df['CONFIDENCE'].std())
    }
    
    # Find minimum confidence (rounded down to nearest 0.05)
    min_conf = valid_df['CONFIDENCE'].min()
    start_threshold = max(0.5, np.floor(min_conf * 20) / 20)
    
    # Compute metrics for different thresholds
    thresholds = {}
    total_correct = valid_df['CORRECT'].sum()
    
    for threshold in np.arange(start_threshold, 1.01, 0.05):
        high_conf = valid_df[valid_df['CONFIDENCE'] >= threshold]
        
        if len(high_conf) > 0:
            n_correct = high_conf['CORRECT'].sum()
            n_incorrect = (~high_conf['CORRECT']).sum()
            precision = n_correct / len(high_conf)
            recall = n_correct / total_correct if total_correct > 0 else 0
            
            if precision + recall > 0:
                f1 = 2 * (precision * recall) / (precision + recall)
            else:
                f1 = 0
            
            thresholds[float(threshold)] = {
                'precision': float(precision),
                'recall': float(recall),
                'f1_score': float(f1),
                'n_samples': int(len(high_conf)),
                'n_correct': int(n_correct),
                'n_incorrect': int(n_incorrect)
            }
    
    # Find optimal thresholds for different objectives
    recommendations = {}
    
    # 1. Maximum F1 Score
    best_f1 = 0
    best_f1_threshold = start_threshold
    
    for threshold, metrics in thresholds.items():
        if metrics['f1_score'] > best_f1:
            best_f1 = metrics['f1_score']
            best_f1_threshold = threshold
    
    recommendations['max_f1'] = {
        'threshold': float(best_f1_threshold),
        'f1_score': float(best_f1),
        'precision': float(thresholds[best_f1_threshold]['precision']),
        'recall': float(thresholds[best_f1_threshold]['recall']),
        'description': 'Optimal balance between precision and recall'
    }
    
    # 2. High Precision (>= target)
    precision_threshold = None
    for threshold in sorted(thresholds.keys(), reverse=True):
        if thresholds[threshold]['precision'] >= precision_target:
            precision_threshold = threshold
            break
    
    if precision_threshold:
        recommendations['high_precision'] = {
            'threshold': float(precision_threshold),
            'precision': float(thresholds[precision_threshold]['precision']),
            'recall': float(thresholds[precision_threshold]['recall']),
            'f1_score': float(thresholds[precision_threshold]['f1_score']),
            'target': float(precision_target),
            'description': f'Achieves precision >= {precision_target}'
        }
    
    # 3. Balanced (precision ≈ recall)
    balanced_threshold = None
    min_diff = float('inf')
    
    for threshold, metrics in thresholds.items():
        diff = abs(metrics['precision'] - metrics['recall'])
        if diff < min_diff:
            min_diff = diff
            balanced_threshold = threshold
    
    if balanced_threshold:
        recommendations['balanced'] = {
            'threshold': float(balanced_threshold),
            'precision': float(thresholds[balanced_threshold]['precision']),
            'recall': float(thresholds[balanced_threshold]['recall']),
            'f1_score': float(thresholds[balanced_threshold]['f1_score']),
            'description': 'Precision and recall are most balanced'
        }
    
    # 4. Conservative (filters all incorrect predictions)
    conservative_threshold = None
    for threshold in sorted(thresholds.keys(), reverse=True):
        if thresholds[threshold]['n_incorrect'] == 0 and thresholds[threshold]['n_samples'] > 0:
            conservative_threshold = threshold
            break
    
    if conservative_threshold:
        recommendations['conservative'] = {
            'threshold': float(conservative_threshold),
            'precision': float(thresholds[conservative_threshold]['precision']),
            'recall': float(thresholds[conservative_threshold]['recall']),
            'f1_score': float(thresholds[conservative_threshold]['f1_score']),
            'description': 'Filters out all incorrect predictions'
        }
    
    # 5. Permissive (includes all predictions with confidence data)
    permissive_threshold = start_threshold
    recommendations['permissive'] = {
        'threshold': float(permissive_threshold),
        'precision': float(thresholds[permissive_threshold]['precision']),
        'recall': float(thresholds[permissive_threshold]['recall']),
        'f1_score': float(thresholds[permissive_threshold]['f1_score']),
        'description': 'Includes all predictions above minimum confidence'
    }
    
    return {
        'thresholds': thresholds,
        'recommendations': recommendations,
        'confidence_stats': confidence_stats
    }

def plot_confidence_distribution(matched_df, output_dir):
    """
    Plot confidence distribution for correct and incorrect predictions.
    
    Args:
        matched_df: DataFrame with matched predictions
        output_dir: Directory to save plots
    """
    # Filter out rows without confidence
    valid_df = matched_df[matched_df['CONFIDENCE'].notna()]
    
    plt.figure(figsize=(12, 6))
    
    # Plot 1: Distribution comparison
    plt.subplot(1, 2, 1)
    correct_conf = valid_df[valid_df['CORRECT'] == True]['CONFIDENCE']
    incorrect_conf = valid_df[valid_df['CORRECT'] == False]['CONFIDENCE']
    
    if len(correct_conf) > 0:
        plt.hist(correct_conf, alpha=0.5, label='Correct', bins=20, color='green')
    if len(incorrect_conf) > 0:
        plt.hist(incorrect_conf, alpha=0.5, label='Incorrect', bins=20, color='red')
    plt.xlabel('Confidence')
    plt.ylabel('Frequency')
    plt.title('Confidence Distribution: Correct vs Incorrect')
    plt.legend()
    
    # Plot 2: Box plot per smell type
    plt.subplot(1, 2, 2)
    smell_conf_data = []
    smell_labels = []
    
    for smell in sorted(valid_df['CATEGORY'].unique()):
        smell_data = valid_df[valid_df['CATEGORY'] == smell]['CONFIDENCE']
        if len(smell_data) > 0:
            smell_conf_data.append(smell_data)
            smell_labels.append(smell)
    
    if len(smell_conf_data) > 0:
        plt.boxplot(smell_conf_data, tick_labels=smell_labels)
        plt.xlabel('Smell Type')
        plt.ylabel('Confidence')
        plt.title('Confidence Distribution per Smell Type')
        plt.xticks(rotation=45, ha='right')
    
    plt.tight_layout()
    plt.savefig(os.path.join(output_dir, 'confidence_distribution.png'), dpi=300, bbox_inches='tight')
    plt.close()

def plot_precision_recall_by_threshold(matched_df, output_dir):
    """
    Plot precision and recall curves by confidence threshold.
    
    Args:
        matched_df: DataFrame with matched predictions
        output_dir: Directory to save plots
    """
    # Filter out rows without confidence
    valid_df = matched_df[matched_df['CONFIDENCE'].notna()].copy()
    
    if len(valid_df) == 0:
        return
    
    # Find minimum confidence
    min_conf = valid_df['CONFIDENCE'].min()
    start_threshold = max(0.5, np.floor(min_conf * 20) / 20)
    
    thresholds = np.arange(start_threshold, 1.01, 0.01)
    precisions = []
    recalls = []
    f1_scores = []
    
    total_correct = valid_df['CORRECT'].sum()
    
    for threshold in thresholds:
        high_conf = valid_df[valid_df['CONFIDENCE'] >= threshold]
        
        if len(high_conf) > 0:
            precision = high_conf['CORRECT'].sum() / len(high_conf)
            recall = high_conf['CORRECT'].sum() / total_correct if total_correct > 0 else 0
            
            if precision + recall > 0:
                f1 = 2 * (precision * recall) / (precision + recall)
            else:
                f1 = 0
        else:
            precision = 0
            recall = 0
            f1 = 0
        
        precisions.append(precision)
        recalls.append(recall)
        f1_scores.append(f1)
    
    plt.figure(figsize=(10, 6))
    plt.plot(thresholds, precisions, label='Precision', marker='o', markersize=3)
    plt.plot(thresholds, recalls, label='Recall', marker='s', markersize=3)
    plt.plot(thresholds, f1_scores, label='F1 Score', marker='^', markersize=3)
    plt.xlabel('Confidence Threshold')
    plt.ylabel('Score')
    plt.title('Precision, Recall, and F1 Score by Confidence Threshold')
    plt.legend()
    plt.grid(True, alpha=0.3)
    plt.savefig(os.path.join(output_dir, 'precision_recall_curve.png'), dpi=300, bbox_inches='tight')
    plt.close()


def save_results(stats, wilcoxon_results, threshold_results, matched_df, output_dir):
    """
    Save all results to files.
    
    Args:
        stats: Dictionary with confidence statistics
        wilcoxon_results: Dictionary with Wilcoxon test results
        threshold_results: Dictionary with threshold analysis
        matched_df: DataFrame with matched predictions
        output_dir: Directory to save results
    """
    # Create output directory
    os.makedirs(output_dir, exist_ok=True)
    
    # Save statistics
    with open(os.path.join(output_dir, 'confidence_statistics.json'), 'w') as f:
        json.dump(stats, f, indent=2)
    
    # Save Wilcoxon test results
    with open(os.path.join(output_dir, 'wilcoxon_test_results.json'), 'w') as f:
        json.dump(wilcoxon_results, f, indent=2)
    
    # Save threshold analysis
    with open(os.path.join(output_dir, 'threshold_analysis.json'), 'w') as f:
        # Convert threshold keys to strings for JSON serialization
        serializable_results = {
            'thresholds': {str(k): v for k, v in threshold_results['thresholds'].items()},
            'recommendations': threshold_results['recommendations'],
            'confidence_stats': threshold_results['confidence_stats']
        }
        json.dump(serializable_results, f, indent=2)
    
    # Save matched dataset
    matched_df.to_csv(os.path.join(output_dir, 'matched_predictions.csv'), index=False)
    
    # Create summary report
    with open(os.path.join(output_dir, 'summary_report.txt'), 'w') as f:
        f.write("=" * 80 + "\n")
        f.write("CONFIDENCE ANALYSIS SUMMARY REPORT\n")
        f.write("=" * 80 + "\n\n")
        
        f.write("OVERALL STATISTICS\n")
        f.write("-" * 80 + "\n")
        f.write(f"Mean Confidence: {stats['overall']['mean']:.4f}\n")
        f.write(f"Median Confidence: {stats['overall']['median']:.4f}\n")
        f.write(f"Std Confidence: {stats['overall']['std']:.4f}\n")
        f.write(f"Min Confidence: {stats['overall']['min']:.4f}\n")
        f.write(f"Max Confidence: {stats['overall']['max']:.4f}\n")
        f.write(f"Count with confidence: {stats['overall']['count_with_confidence']}\n")
        f.write(f"Count without confidence (no prediction): {stats['overall']['count_without_confidence']}\n\n")
        
        f.write("CORRECT vs INCORRECT PREDICTIONS\n")
        f.write("-" * 80 + "\n")
        f.write(f"Correct Predictions:\n")
        f.write(f"  Count: {stats['correct']['count']}\n")
        f.write(f"  Count with confidence: {stats['correct']['count_with_confidence']}\n")
        if stats['correct']['mean'] is not None:
            f.write(f"  Mean Confidence: {stats['correct']['mean']:.4f}\n")
            f.write(f"  Median Confidence: {stats['correct']['median']:.4f}\n")
        f.write(f"\nIncorrect Predictions:\n")
        f.write(f"  Count: {stats['incorrect']['count']}\n")
        f.write(f"  Count with confidence: {stats['incorrect']['count_with_confidence']}\n")
        if stats['incorrect']['mean'] is not None:
            f.write(f"  Mean Confidence: {stats['incorrect']['mean']:.4f}\n")
            f.write(f"  Median Confidence: {stats['incorrect']['median']:.4f}\n\n")
        
        f.write("CONFIDENCE BY SMELL TYPE (Ground Truth)\n")
        f.write("-" * 80 + "\n")
        for smell in sorted(stats['per_smell'].keys()):
            smell_stats = stats['per_smell'][smell]
            f.write(f"\n{smell}:\n")
            f.write(f"  Total count: {smell_stats['count']}\n")
            f.write(f"  Count with confidence: {smell_stats['count_with_confidence']}\n")
            f.write(f"  Count without confidence: {smell_stats['count_without_confidence']}\n")
            if smell_stats['mean'] is not None:
                f.write(f"  Overall Mean: {smell_stats['mean']:.4f}\n")
                f.write(f"  Overall Median: {smell_stats['median']:.4f}\n")
                f.write(f"  Overall Std: {smell_stats['std']:.4f}\n")
            
            # Add correct/incorrect breakdown
            f.write(f"\n  Correct Predictions:\n")
            if smell_stats['correct']['mean'] is not None:
                f.write(f"    Count: {smell_stats['correct']['count']}\n")
                f.write(f"    Mean Confidence: {smell_stats['correct']['mean']:.4f}\n")
                f.write(f"    Median Confidence: {smell_stats['correct']['median']:.4f}\n")
                f.write(f"    Std Confidence: {smell_stats['correct']['std']:.4f}\n")
            else:
                f.write(f"    Count: {smell_stats['correct']['count']}\n")
                f.write(f"    No confidence values\n")
            
            f.write(f"\n  Incorrect Predictions:\n")
            if smell_stats['incorrect']['mean'] is not None:
                f.write(f"    Count: {smell_stats['incorrect']['count']}\n")
                f.write(f"    Mean Confidence: {smell_stats['incorrect']['mean']:.4f}\n")
                f.write(f"    Median Confidence: {smell_stats['incorrect']['median']:.4f}\n")
                f.write(f"    Std Confidence: {smell_stats['incorrect']['std']:.4f}\n")
            else:
                f.write(f"    Count: {smell_stats['incorrect']['count']}\n")
                f.write(f"    No confidence values\n")
        
        f.write("\n" + "=" * 80 + "\n")
        f.write("WILCOXON RANK-SUM TEST RESULTS\n")
        f.write("=" * 80 + "\n")
        if 'overall' in wilcoxon_results:
            f.write(f"Overall Test:\n")
            f.write(f"  Statistic: {wilcoxon_results['overall']['statistic']:.4f}\n")
            f.write(f"  P-value: {wilcoxon_results['overall']['p_value']:.6f}\n")
            f.write(f"  Significant (α=0.05): {wilcoxon_results['overall']['significant']}\n")
            f.write(f"  N correct: {wilcoxon_results['overall']['n_correct']}\n")
            f.write(f"  N incorrect: {wilcoxon_results['overall']['n_incorrect']}\n\n")
        
        per_smell_tests = {k: v for k, v in wilcoxon_results.items() if k != 'overall'}
        
        if len(per_smell_tests) > 0:
            f.write("Per-Smell Tests (with Holm-Bonferroni correction):\n")
            for smell in sorted(per_smell_tests.keys()):
                results = per_smell_tests[smell]
                f.write(f"\n{smell}:\n")
                f.write(f"  Statistic: {results['statistic']:.4f}\n")
                f.write(f"  P-value: {results['p_value']:.6f}\n")
                if 'p_value_corrected' in results:
                    f.write(f"  P-value (corrected): {results['p_value_corrected']:.6f}\n")
                    f.write(f"  Significant (corrected): {results['significant_corrected']}\n")
                f.write(f"  N correct: {results['n_correct']}\n")
                f.write(f"  N incorrect: {results['n_incorrect']}\n")
        else:
            f.write("Per-Smell Tests:\n")
            f.write("  No tests performed (insufficient data for per-smell comparison)\n")
        
        f.write("\n" + "=" * 80 + "\n")
        f.write("THRESHOLD RECOMMENDATIONS\n")
        f.write("=" * 80 + "\n\n")
        
        f.write("Confidence Distribution:\n")
        conf_stats = threshold_results['confidence_stats']
        f.write(f"  Min: {conf_stats['min']:.4f}\n")
        f.write(f"  Max: {conf_stats['max']:.4f}\n")
        f.write(f"  Mean: {conf_stats['mean']:.4f}\n")
        f.write(f"  Median: {conf_stats['median']:.4f}\n")
        f.write(f"  Std: {conf_stats['std']:.4f}\n\n")
        
        f.write("Recommended Thresholds by Objective:\n")
        f.write("-" * 80 + "\n")
        
        for key, rec in threshold_results['recommendations'].items():
            f.write(f"\n{key.upper().replace('_', ' ')}:\n")
            f.write(f"  Threshold: {rec['threshold']:.2f}\n")
            f.write(f"  Precision: {rec['precision']:.4f}\n")
            f.write(f"  Recall: {rec['recall']:.4f}\n")
            f.write(f"  F1 Score: {rec['f1_score']:.4f}\n")
            if 'description' in rec:
                f.write(f"  Description: {rec['description']}\n")
        
        f.write("\n" + "-" * 80 + "\n")
        f.write("Detailed Threshold Analysis:\n")
        f.write("-" * 80 + "\n")
        
        for threshold in sorted(threshold_results['thresholds'].keys()):
            metrics = threshold_results['thresholds'][threshold]
            f.write(f"\nThreshold >= {threshold:.2f}:\n")
            f.write(f"  Precision: {metrics['precision']:.4f}\n")
            f.write(f"  Recall: {metrics['recall']:.4f}\n")
            f.write(f"  F1 Score: {metrics['f1_score']:.4f}\n")
            f.write(f"  N Samples: {metrics['n_samples']} (Correct: {metrics['n_correct']}, Incorrect: {metrics['n_incorrect']})\n")


def print_summary(stats, wilcoxon_results, threshold_results):
    """
    Print summary to console.
    
    Args:
        stats: Dictionary with confidence statistics
        wilcoxon_results: Dictionary with Wilcoxon test results
        threshold_results: Dictionary with threshold analysis
    """
    print("\n" + "=" * 80)
    print("CONFIDENCE ANALYSIS SUMMARY")
    print("=" * 80)
    
    print("\nOVERALL CONFIDENCE STATISTICS:")
    print(f"  Mean: {stats['overall']['mean']:.4f}")
    print(f"  Median: {stats['overall']['median']:.4f}")
    print(f"  Std: {stats['overall']['std']:.4f}")
    print(f"  Range: [{stats['overall']['min']:.4f}, {stats['overall']['max']:.4f}]")
    print(f"  Predictions with confidence: {stats['overall']['count_with_confidence']}")
    print(f"  Predictions without confidence: {stats['overall']['count_without_confidence']}")
    
    print("\nCONFIDENCE BY PREDICTION CORRECTNESS:")
    if stats['correct']['mean'] is not None:
        print(f"  Correct   - Mean: {stats['correct']['mean']:.4f}, Count: {stats['correct']['count_with_confidence']}/{stats['correct']['count']}")
    else:
        print(f"  Correct   - No confidence values, Count: {stats['correct']['count']}")
    
    if stats['incorrect']['mean'] is not None:
        print(f"  Incorrect - Mean: {stats['incorrect']['mean']:.4f}, Count: {stats['incorrect']['count_with_confidence']}/{stats['incorrect']['count']}")
    else:
        print(f"  Incorrect - No confidence values, Count: {stats['incorrect']['count']}")
    
    print("\nCONFIDENCE BY SMELL TYPE:")
    for smell in sorted(stats['per_smell'].keys()):
        smell_stats = stats['per_smell'][smell]
        if smell_stats['mean'] is not None:
            print(f"\n  {smell}:")
            print(f"    Overall: Mean={smell_stats['mean']:.4f}, Median={smell_stats['median']:.4f}, N={smell_stats['count_with_confidence']}/{smell_stats['count']}")
            
            # Print correct/incorrect breakdown
            if smell_stats['correct']['mean'] is not None:
                print(f"    Correct: Mean={smell_stats['correct']['mean']:.4f}, N={smell_stats['correct']['count']}")
            else:
                print(f"    Correct: N={smell_stats['correct']['count']} (no confidence)")
            
            if smell_stats['incorrect']['mean'] is not None:
                print(f"    Incorrect: Mean={smell_stats['incorrect']['mean']:.4f}, N={smell_stats['incorrect']['count']}")
            else:
                print(f"    Incorrect: N={smell_stats['incorrect']['count']} (no confidence)")
        else:
            print(f"  {smell}: No confidence values, N={smell_stats['count']}")
    
    print("\nWILCOXON TEST RESULTS:")
    if 'overall' in wilcoxon_results:
        print(f"  Overall: p-value={wilcoxon_results['overall']['p_value']:.6f}, Significant={wilcoxon_results['overall']['significant']}")
    
    per_smell_tests = {k: v for k, v in wilcoxon_results.items() if k != 'overall'}
    if len(per_smell_tests) > 0:
        print(f"  Per-smell tests performed: {len(per_smell_tests)}")
        print(f"  (See summary_report.txt for details)")
    else:
        print(f"  Per-smell tests: None performed (insufficient data)")
    
    print("\nTHRESHOLD RECOMMENDATIONS:")
    if 'recommendations' in threshold_results and len(threshold_results['recommendations']) > 0:
        for key, rec in threshold_results['recommendations'].items():
            print(f"\n  {key.upper().replace('_', ' ')}:")
            print(f"    Threshold: {rec['threshold']:.2f}")
            print(f"    Precision: {rec['precision']:.4f}")
            print(f"    Recall: {rec['recall']:.4f}")
            print(f"    F1 Score: {rec['f1_score']:.4f}")
    
    print("\n" + "=" * 80)

def main():
    """
    Main function to run the confidence analysis.
    """
    parser = argparse.ArgumentParser(
        description='Analyze confidence values in code smell predictions'
    )
    parser.add_argument(
        '--predictions',
        type=str,
        required=True,
        help='Path to predictions dataset (JSON or CSV)'
    )
    parser.add_argument(
        '--ground-truth',
        type=str,
        required=True,
        help='Path to ground truth dataset (CSV)'
    )
    parser.add_argument(
        '--output-dir',
        type=str,
        default='confidence_analysis_results',
        help='Directory to save results (default: confidence_analysis_results)'
    )
    parser.add_argument(
        '--precision-target',
        type=float,
        default=0.95,
        help='Target precision for threshold determination (default: 0.95)'
    )
    
    args = parser.parse_args()
    
    # Load datasets
    print("Loading datasets...")
    smell_dataset = load_dataset(args.predictions)
    oracle_dataset = load_dataset(args.ground_truth)
    
    print(f"Loaded {len(smell_dataset)} predictions and {len(oracle_dataset)} ground truth samples")
    
    # Match predictions with ground truth
    print("\nMatching predictions with ground truth...")
    matched_df = match_predictions_with_ground_truth(smell_dataset, oracle_dataset)
    print(f"Matched {len(matched_df)} samples")
    print(f"  - With confidence: {matched_df['CONFIDENCE'].notna().sum()}")
    print(f"  - Without confidence (no prediction): {matched_df['CONFIDENCE'].isna().sum()}")
    
    # Compute statistics
    print("\nComputing confidence statistics...")
    stats = compute_confidence_statistics(matched_df)
    
    # Perform Wilcoxon test
    print("\nPerforming Wilcoxon Rank-Sum Tests...")
    wilcoxon_results = perform_wilcoxon_test(matched_df)
    
    # Determine thresholds
    print("\nDetermining confidence thresholds...")
    threshold_results = determine_confidence_thresholds(matched_df, args.precision_target)
    
    # Create visualizations
    print("\nCreating visualizations...")
    plot_confidence_distribution(matched_df, args.output_dir)
    plot_precision_recall_by_threshold(matched_df, args.output_dir)
    
    # Save results
    print(f"\nSaving results to {args.output_dir}...")
    save_results(stats, wilcoxon_results, threshold_results, matched_df, args.output_dir)
    
    # Print summary
    print_summary(stats, wilcoxon_results, threshold_results)
    
    print(f"\nAnalysis complete! Results saved to: {args.output_dir}")

if __name__ == "__main__":
    main()