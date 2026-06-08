from configurator import *
from preprocessor import *
from ensemble import *
from analyzer import *
import os
from concurrent.futures import ThreadPoolExecutor
import time
import argparse
import csv
import traceback
from rich import print
from rich.markup import escape

from tqdm import tqdm
import json

def builtin_print(*args, **kwargs):
    import builtins
    builtins.print(*args, **kwargs)

def rich_print(s):
    try:
        # Usa la funzione escape di rich per gestire tutti i caratteri speciali
        escaped_msg = escape(str(s))
        print(escaped_msg)
    except Exception as e:
        # Fallback al print normale
        builtin_print(s)

#
# SecLLM main class. 
#
class SecLLM:

    def __init__(self, config="config.yaml"):
        self.configurator = Configurator(config)
        self.smells = self.configurator.config.smells
        self.preprocessor = ScriptPreprocessor(self.configurator)
        self.analyzer = SmellAnalyzer(self.configurator)
        self.tokens = []
        self.ensemble = False
        self.instances = 1
        self.parallel = True
    #
    # Force SecLLM to detect only the provided smell names
    #
    def filterSmells(self, names):
        r = self.configurator.getSmellsByNames(names)
        self.smells = r 


    #
    # Load the script and add line numbers
    #  
    def _loadScript(self, file_path):
        """
        This function takes the path of a script file, reads its content, adds a line number
        before each line, and returns the modified script with numbered lines.
        
        :param file_path: Path to the script file.
        :return: A string with line numbers prepended to each line.
        """
        return self.preprocessor._loadScript(file_path)


    def setEnsemble(self, instances, parallel):
        self.ensemble = True
        self.instances = instances
        self.parallel = parallel

    #
    # Analyze the script for the given smell
    #
    def checkSmell(self, name, scriptName, script):
        script_type, script, prompt = self.preprocessor.preprocess(name, scriptName, script)
        #print("Script:\n")
        builtin_print(f"[*] Evaluando regla '{name}' en archivo '{scriptName}'...")

        if len(script.strip()) == 0:
            return None
        
        if self.ensemble:
            ensemble = EnsembleManager(
                func=self.analyzer.analyze,
                n_instances=self.instances,
                parallel=self.parallel)
            detailed= ensemble.run(script_type, name, prompt, script, self.tokens)
            return detailed
        else:
            return self.analyzer.analyze(script_type, name, prompt, script, self.tokens)
    
    def checkSmells(self, file_path, threads):
        """
        This method processes the script file by adding line numbers and then checks 
        all smells concurrently on the processed script.
        
        :param file_path: Path to the script file.
        :return: A list of results from checking all smells.
        """
        self.tokens = []
        # First, process the script to add line numbers
        processed_script = self._loadScript(file_path)
        
        workers = threads if threads >0 else len(self.smells)

        # Create a list to store future results from the checkSmell method
        results = []

        start_time = time.time()
        # Use ThreadPoolExecutor to utilize multiple threads for I/O-bound tasks
        with ThreadPoolExecutor(max_workers=workers) as executor:
            # Submit tasks for each smell to the executor
            futures = {
                executor.submit(self.checkSmell, smell['name'], file_path, processed_script): smell['name']
                for smell in self.smells
            }

            # Collect the results as they complete
            for future in futures:
                smell_name = futures[future]
                try:
                    result = future.result()  # Get the result of checkSmell
                    if result is not None:
                        #result['file'] = file_path
                        results.append(result)
                except Exception as e:
                    builtin_print(f"Error processing smell '{smell_name}': {e}")
                    stack_trace = traceback.format_exc()
                    builtin_print(stack_trace)
                    builtin_print("\n\n")
        end_time = time.time()
        # Calculate the execution time
        execution_time = end_time - start_time

        intk = 0
        outtk = 0
        for t in self.tokens:
            intk += t["input"]
            outtk += t["output"]
        return {"file":file_path, "smells":results, "time":execution_time, "input":intk, "output":outtk}

    #
    # Process a full directory scan.
    #
    def processDirectory(self, dir_path, threads):
        """Processes all script files in a given directory concurrently."""
        results = {}
        workers = threads if threads > 0 else min(len(os.listdir(dir_path)), 10)
        # Use ThreadPoolExecutor to process multiple files concurrently
        with ThreadPoolExecutor(max_workers=workers) as executor:
            futures = {
                executor.submit(self.checkSmells, os.path.join(root, file), threads): os.path.join(root, file)
                for root, dirs, files in os.walk(dir_path)
                for file in files  # Process YAML files
            }

            #for future in futures:
            for future in tqdm(futures, 
                               total=len(futures),
                               desc="Processing files",
                               unit="file"):
                file_path = futures[future]
                try:
                    result = future.result()
                    results[file_path] = result
                except Exception as e:
                    builtin_print(f"Error processing file '{file_path}': {e}")
        end = time.time()

        return results

    #
    # Write the results to the provided csv file
    #
    def writeResultsToCSV(self, results, output_file, append=False):
        """Writes the results to a CSV file."""
        mode = 'a' if append else 'w'
        with open(output_file, mode=mode, newline='') as file:
            writer = csv.writer(file)
            if not append:
                writer.writerow(["PATH", "LINE", "SMELL", "TIME", "TOKEN_IN", "TOKEN_OUT"])

            for file_path, result in results.items():
                # Extract only the filename from the path
                file_name = os.path.basename(file_path)
                
                # If there are no smells found in the file
                if len(result["smells"]) == 0:
                    writer.writerow([file_name, 0, 'none', result["time"], result["input"], result["output"]])
                else:
                    # Write each smell found in the file
                    for smell in result["smells"]:
                        for line in smell["lines"]:
                            writer.writerow([file_name, line, smell["smell"], result["time"],result["input"], result["output"] ])

    #
    # Write the results to the provided json file
    #
    def writeResultsToJSON(self, results, output_file, append=False):
        """Writes the results to a JSON file."""
        json_data = []
        
        # If appending, read existing data first
        if append:
            try:
                with open(output_file, 'r') as file:
                    json_data = json.load(file)
            except (json.JSONDecodeError, FileNotFoundError):
                json_data = []
        
        for file_path, result in results.items():
            # Extract only the filename from the path
            file_name = os.path.basename(file_path)
            
            # If there are no smells found in the file
            if len(result["smells"]) == 0:
                json_data.append({
                    "PATH": file_name,
                    "LINE": 0,
                    "SMELL": "none",
                    "TIME": result["time"],
                    "TOKEN_IN": result["input"],
                    "TOKEN_OUT": result["output"]
                })
            else:
                not_found = True
                max_confidence = 0.0
                # Write each smell found in the file
                for smell in result["smells"]:
                    confidence = smell.get('confidence')
                    # Local backends (e.g. Ollama) don't return logprobs, so
                    # confidence may be None. Fall back to 1.0 in that case.
                    if confidence is None:
                        confidence = 1.0
                    max_confidence = max(max_confidence, confidence)
                    for line in smell["lines"]:
                        not_found = False
                        json_data.append({
                            "PATH": file_name,
                            "LINE": line,
                            "SMELL": smell["smell"],
                            "TIME": result["time"],
                            "TOKEN_IN": result["input"],
                            "TOKEN_OUT": result["output"],
                            "CONFIDENCE": confidence
                        })
                if not_found:
                    json_data.append({
                        "PATH": file_name,
                        "LINE": 0,
                        "SMELL": "none",
                        "TIME": result["time"],
                        "TOKEN_IN": result["input"],
                        "TOKEN_OUT": result["output"],
                        "CONFIDENCE": max_confidence
                    })
        
        # Write the JSON data to file
        with open(output_file, 'w') as file:
            json.dump(json_data, file, indent=2)

#
# Print the results
#
def printResults(result, directory=False):
    #print(result)
    if not directory:
        res = result.get('smells', [])
        rich_print(f"\nFile: {result['file']}\n")
        rich_print("=" * 40)

        for r in res:
            if not r.get('smell', None):
                continue
            rich_print(f"Smell: {r['smell']}")
            rich_print(f"Description: {r['description']}")
            rich_print(f"Lines: {', '.join(map(str, r['lines']))}")
            rich_print(f"Analysis:\n{r['analysis']}")
            rich_print(f"Confidence: {r.get('confidence',1.0)}")
            rich_print("-" * 40)
        rich_print(f"Time: {result['time']}")
        rich_print(f"Input Tokens: {result['input']}")
        rich_print(f"Output Tokens: {result['output']}\n")
        rich_print("=" * 40)
    else:
        for rx in result.keys():
            r = result[rx]
            #print(r)
            res = r.get('smells', [])
            rich_print(f"\nFile: {r['file']}\n")
            rich_print("=" * 40)
            for rs in res:
                rich_print(f"Smell: {rs['smell']}")
                rich_print(f"Description: {rs['description']}")
                rich_print(f"Lines: {', '.join(map(str, rs['lines']))}")
                rich_print(f"Analysis:\n{rs['analysis']}")
                rich_print(f"Confidence: {rs.get('confidence',1.0)}")
                rich_print("-" * 40)
            rich_print(f"Time: {r.get('time',0)}")
            rich_print(f"Input Tokens: {r['input']}")
            rich_print(f"Output Tokens: {r['output']}\n")
            rich_print("=" * 40)

def main():

    parser = argparse.ArgumentParser(description="Process script files for security smells.")
    parser.add_argument("-c", "--config", help="Path to the configuration file", default="config.yaml")
    parser.add_argument("-f", "--file", help="Path to a single file to check")
    parser.add_argument("-d", "--directory", help="Path to the directory of files to check")
    parser.add_argument("-o", "--output", help="Output CSV file for results")
    parser.add_argument("-a", "--append", action="store_true", help="Append to the output file instead of overwriting")
    parser.add_argument("-s", "--smell", help="Specific smell to check")
    parser.add_argument("-t", "--threads",type=int, default=-1, help='Number of threads to use.')
    parser.add_argument("-j", "--json",action="store_true", help='JSON format for the output')
    parser.add_argument("-e", "--ensemble", action="store_true", help="Use ensemble for inference")
    parser.add_argument("-i", "--instances",type=int, default=5, help='Number ensemble instances.')
    parser.add_argument("-p", "--not_parallel", action="store_true", help="Use ensemble sequencially")


    args = parser.parse_args()

    # Initialize SecLLM object
    checker = SecLLM(config=args.config)

    if args.ensemble:
        checker.setEnsemble(args.instances, not args.not_parallel)

    if args.smell:
        checker.filterSmells([args.smell])

    if args.file:
        # Process a single file
        result = checker.checkSmells(args.file, args.threads)
        
        if args.output:
            if args.json:
                checker.writeResultsToJSON({args.file: result}, args.output, append=args.append)
            else:
                checker.writeResultsToCSV({args.file: result}, args.output, append=args.append)
        else:
            printResults(result)
    elif args.directory:
        # Process all files in a directory
        start_time = time.time()
        result = checker.processDirectory(args.directory, args.threads)
        end_time = time.time()
        print("TOTAL TIME", end_time-start_time)
        if args.output:
            if args.json:
                checker.writeResultsToJSON(result, args.output, append=args.append)
            else:
                checker.writeResultsToCSV(result, args.output, append=args.append)
        else:
            printResults(result, True)
    else:
        print("Please provide either a file (-f) or a directory (-d) to process.")

if __name__ == '__main__':
    main()