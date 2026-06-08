import pandas as pd
import argparse

def main(filename):
    # Read CSV/JSON
    if filename.endswith("csv"):
        try:
            df = pd.read_csv(filename, sep=";")
        except Exception as e:
            df = pd.read_csv(filename, sep=",")
    else:
        df = pd.read_json(filename)

    df['TIME'] = pd.to_numeric(df['TIME'], errors='coerce')
    df.dropna(subset=['TIME'], inplace=True)

    df['TOKEN_IN'] = pd.to_numeric(df['TOKEN_IN'], errors='coerce')
    df.dropna(subset=['TOKEN_IN'], inplace=True)

    df['TOKEN_OUT'] = pd.to_numeric(df['TOKEN_OUT'], errors='coerce')
    df.dropna(subset=['TOKEN_OUT'], inplace=True)

    # Dato che TIME è unico per PATH, prendiamo un valore per PATH
    # e contiamo quanti smell ci sono per ogni PATH
    grouped = df.groupby('PATH').agg(
        time=('TIME', 'first'),  # Tempo unico per il PATH
        smell_count=('SMELL', 'count'),  # Numero di smell per PATH
        unique_smells=('SMELL', 'nunique')  # Numero di smell unici per PATH
    ).reset_index()

    # Statistiche globali sui tempi (un tempo per PATH)
    times = grouped['time']
    
    total_paths = len(grouped)
    total_time = times.sum()
    avg_time = times.mean()
    std_time = times.std()
    median_time = times.median()
    total_smells = grouped['smell_count'].sum()

    print("=== GLOBAL STATISTICS ===")
    print(f"Number of scripts: {total_paths}")
    print(f"Number of smells: {total_smells}")
    print(f"TOTAL TIME: {total_time:.8f}")
    print(f"AVG TIME per script: {avg_time:.8f}")
    print(f"STANDARD DEVIATION: {std_time:.8f}")
    print(f"MEDIAN TIME: {median_time:.8f}")
    
    # Statistiche aggiuntive sugli smell
    print(f"AVG smell per PATH: {grouped['smell_count'].mean():.2f}")
    print(f"AVG unique smell per PATH: {grouped['unique_smells'].mean():.2f}")

    # Raggruppamento per TOKEN_IN
    grouped_token_in = df.groupby('PATH').agg(
        token_in=('TOKEN_IN', 'first'),  # token_in per PATH
        smell_count=('SMELL', 'count'),  # Numero di smell per PATH
        unique_smells=('SMELL', 'nunique')  # Numero di smell unici per PATH
    ).reset_index()
    token_ins = grouped_token_in['token_in']  # Usa 'token_in' non 'TOKEN_IN'
    total_token_in = token_ins.sum()

    # Raggruppamento per TOKEN_OUT
    grouped_token_out = df.groupby('PATH').agg(
        token_out=('TOKEN_OUT', 'first'),  # token_out per PATH
        smell_count=('SMELL', 'count'),  # Numero di smell per PATH
        unique_smells=('SMELL', 'nunique')  # Numero di smell unici per PATH
    ).reset_index()
    token_outs = grouped_token_out['token_out']  # Usa 'token_out' non 'TOKEN_OUT'
    total_token_out = token_outs.sum()

    print("\n")
    print("=======================")
    print(f"TOTAL Token in: {total_token_in:.8f}")
    print(f"TOTAL Token out: {total_token_out:.8f}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Process a CSV/JSON file and compute statistics for TIME.')
    parser.add_argument('filename', type=str, help='File path')
    
    args = parser.parse_args()
    main(args.filename)