import argparse
from tqdm import tqdm
from openai import OpenAI
import time
import os
import traceback
import pandas as pd

client = OpenAI(api_key=os.environ.get("OPENAI_API_KEY"),)

def check_smells(model, function_code, script_type="Ansible", backoff_factor=1.0):
    if script_type == "Ansible":
        USER_ZERO_SHOT = """The tool GLITCH can identify the following smells:
Admin by default, Empty password, Hard-coded secret, Unrestricted IP Address, Suspicious comment, Use of HTTP without SSL/TLS, Use of weak cryptography algorithms, No integrity check
Analyze the following Ansible IaC script, from the GLITCH dataset, and provide the smell categories and, for each smell, report the line number where it occurs.

{script}
"""
    elif script_type == "Chef":
        USER_ZERO_SHOT = """The tool GLITCH can identify the following smells:
Admin by default, Empty password, Hard-coded secret, Unrestricted IP Address, Suspicious comment, Use of HTTP without SSL/TLS, Use of weak cryptography algorithms, No integrity check, Missing Default in Case Statement
Analyze the following Chef IaC script, from the GLITCH dataset, and provide the smell categories and, for each smell, report the line number where it occurs.

{script}
"""        
    else:
        USER_ZERO_SHOT = """The tool GLITCH can identify the following smells:
Admin by default, Empty password, Hard-coded secret, Unrestricted IP Address, Suspicious comment, Use of HTTP without SSL/TLS, Use of weak cryptography algorithms, No integrity check, Missing Default in Case Statement
Analyze the following Puppet IaC script, from the GLITCH dataset, and provide the smell categories and, for each smell, report the line number where it occurs.

{script}
"""         

    for attempt in range(5):
        try:
            msg = [{"role": "system", "content": ""}]
            msg.append({"role": "user", "content":  USER_ZERO_SHOT.format(script=function_code)})

            response = client.chat.completions.create(model=model,
                                            messages=msg,
                                            seed=123,
                                            max_tokens=1000,
                                            temperature = 0)
            cleaned_text = response.choices[0].message.content
            return cleaned_text
        except Exception as e:
                print("An error occurred during processing.")
                print(traceback.format_exc())
                wait = backoff_factor * (2 ** attempt)
                time.sleep(wait)
    raise Exception(f"Max retries exceeded {model}")


def open_dataset(smell_file):
    try:
        smell_dataset = pd.read_csv(smell_file, sep=",")  # File with columns PATH, LINE, SMELL
    except Exception as e:
        smell_dataset = pd.read_csv(smell_file, sep=";")
    
    return smell_dataset


def main(repo_path, dataset_file, out_path, model, script_type):
    print(f"Opening {dataset_file}")
    dataset = open_dataset(dataset_file)

    for _, row in tqdm(dataset.iterrows(),"Analyzing scripts..."):
        path, line, category = row["PATH"], row["LINE"], row["CATEGORY"]
        
        f = os.path.join(repo_path,path)
        with open(f, 'r') as file:
            lines = file.readlines()

        script = "".join(lines)
        r = check_smells(model, script, script_type)

        base, ext = os.path.splitext(path)
        fo = os.path.join(out_path, base+".txt")
        with open(fo, 'w', encoding='utf-8') as f:
            f.write(r)



if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Smells zero-shot in the dataset.")
    parser.add_argument('path', type=str, help='Oracle dataset path')
    parser.add_argument('dataset', type=str, help='Oracle dataset')
    parser.add_argument('output', type=str, help='Output path for the experiment')
    parser.add_argument('--model', type=str, default='gpt-4o', help='Model to use for the classification.')
    parser.add_argument('--script', type=str, default='Ansible', help='IaC script type.')

    args = parser.parse_args()
    main(args.path, args.dataset, args.output, args.model, args.script)