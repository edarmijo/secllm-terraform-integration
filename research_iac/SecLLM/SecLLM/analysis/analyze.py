import pandas as pd
from sklearn.metrics import confusion_matrix
import argparse


def load_data(smell_file, oracle_file):
    result = []
    # Load the data from CSV files
    try:
        if smell_file.endswith("csv"):
            smell_dataset = pd.read_csv(smell_file, sep=",")  # File with columns PATH, LINE, SMELL
        elif smell_file.endswith("xlsx"):
            smell_dataset = pd.read_excel(smell_file)
        else:
            smell_dataset = pd.read_json(smell_file)
        oracle_dataset = pd.read_csv(oracle_file)  # File with columns PATH, LINE, CATEGORY
        # First iteration
        for _, row in oracle_dataset.iterrows():
            path, line, category = row["PATH"], row["LINE"], row["CATEGORY"]
            match = smell_dataset[(smell_dataset["PATH"] == path) & (smell_dataset["LINE"] == line) & (smell_dataset["SMELL"] == category)]
            
            if not match.empty:
                # add row
                result.append({"PATH": path, "LINE": line, "SMELL": category, "CATEGORY": category})
            elif category != 'none':
                # add a row with SMELL='none'
                result.append({"PATH": path, "LINE": line, "SMELL": "none", "CATEGORY": category})
    except Exception as e:
        if smell_file.endswith("csv"):
            smell_dataset = pd.read_csv(smell_file, sep=";")
        elif smell_file.endswith("xlsx"):
            smell_dataset = pd.read_excel(smell_file)
        else:
            smell_dataset = pd.read_json(smell_file)
        oracle_dataset = pd.read_csv(oracle_file)  # File with columns PATH, LINE, CATEGORY
        # First iteration
        for _, row in oracle_dataset.iterrows():
            path, line, category = row["PATH"], row["LINE"], row["CATEGORY"]
            match = smell_dataset[(smell_dataset["PATH"] == path) & (smell_dataset["LINE"] == line) & (smell_dataset["SMELL"] == category)]
            
            if not match.empty:
                # add row
                result.append({"PATH": path, "LINE": line, "SMELL": category, "CATEGORY": category})
            elif category != 'none':
                # add a row with SMELL='none'
                result.append({"PATH": path, "LINE": line, "SMELL": "none", "CATEGORY": category})

    if 'TOKEN_IN' in smell_dataset.columns:
        # Prendi solo il primo valore per ogni combinazione PATH-SMELL
        token_in_grouped = smell_dataset.groupby(['PATH', 'SMELL'])['TOKEN_IN'].first()
        token_in_total = token_in_grouped.sum()
        print(f"Total TOKEN_IN: {token_in_total}")
        #print(f"TOKEN_IN breakdown:\n{token_in_grouped}")
    else:
        print("Column TOKEN_IN not found")

    if 'TOKEN_OUT' in smell_dataset.columns:
        # Prendi solo il primo valore per ogni combinazione PATH-SMELL
        token_out_grouped = smell_dataset.groupby(['PATH', 'SMELL'])['TOKEN_OUT'].first()
        token_out_total = token_out_grouped.sum()
        print(f"Total TOKEN_OUT: {token_out_total}")
        #print(f"TOKEN_OUT breakdown:\n{token_out_grouped}")
    else:
        print("Column TOKEN_OUT not found")


    # Second iteration
    for _, row in smell_dataset.iterrows():
        path, line, smell = row["PATH"], row["LINE"], row["SMELL"]
        match = next((r for r in result if r["PATH"] == path and r["LINE"] == line and r["SMELL"] == smell), None)
        
        if not match and smell != 'none':
            # Add row with CATEGORY='none'
            result.append({"PATH": path, "LINE": line, "SMELL": smell, "CATEGORY": "none"})

    # Convert the result to a DataFrame 
    final_result = pd.DataFrame(result)

    # Sort for readability
    final_result = final_result.sort_values(by=["LINE", "CATEGORY", "SMELL"]).reset_index(drop=True)
    return final_result



def compute_metrics_per_category(df_merged):
    # Compute the confusion matrix
    conf_matrix = confusion_matrix(df_merged['CATEGORY'], df_merged['SMELL'])
    
    # Calculate the metrics for each category
    categories = sorted(df_merged['CATEGORY'].unique())

    total_acc = 0
    total_prec = 0
    total_rec = 0
    total_f1 = 0

    count = 0
    print("\n==========================")
    for category in categories:
        if category == 'none':
            # Per la categoria 'none', contiamo gli script senza smell
            #TP = len(df_merged[(df_merged['CATEGORY'] == 'none') & (df_merged['SMELL'] == 'none')])
            #FP = len(df_merged[(df_merged['CATEGORY'] != 'none') & (df_merged['SMELL'] == 'none')])
            #FN = len(df_merged[(df_merged['CATEGORY'] == 'none') & (df_merged['SMELL'] != 'none')])
            #TN = len(df_merged[(df_merged['CATEGORY'] != 'none') & (df_merged['SMELL'] != 'none')])

            # For no mell, we must reason at file level.
            all_files = set(df_merged['PATH'].unique())
            total_files = len(all_files)
            
            #**TP (True Positive)**: Files with no smell and predicted with no smell
            #- Oracolo: "none" 
            #- Predizione: "none"
            tp_files = set(df_merged[(df_merged['CATEGORY'] == 'none') & (df_merged['SMELL'] == 'none')]['PATH'].unique())
            TP = len(tp_files)

            #**FN (False Negative)**: Files with no smell but predicted one or more smells
            #- Oracle: "none"
            #- Prediction: one or more smells
            fn_files = set(df_merged[(df_merged['CATEGORY'] == 'none') & (df_merged['SMELL'] != 'none')]['PATH'].unique())
            FN = len(fn_files)

            #**FP (False Positive)**: Files with smells but predicted as "none" 
            #- Oracle: one or more smells
            #- Prediction: "none"
            fp_files = set(df_merged[(df_merged['CATEGORY'] != 'none') & (df_merged['SMELL'] == 'none')]['PATH'].unique())
            FP = len(fp_files)
            total = total_files

            #**TN is the difference
            TN  = total - FP -FN -TP 
        else:
            TP = len(df_merged[(df_merged['CATEGORY'] == category) & (df_merged['SMELL'] == category)])
            FP = len(df_merged[(df_merged['CATEGORY'] != category) & (df_merged['SMELL'] == category)])
            FN = len(df_merged[(df_merged['CATEGORY'] == category) & (df_merged['SMELL'] != category)])
            TN = len(df_merged[(df_merged['CATEGORY'] != category) & (df_merged['SMELL'] != category)])

        # Compute metrics for each category
        total = TP + TN + FP + FN
        accuracy = (TP + TN) / total if total != 0 else 0
        precision = TP / (TP + FP) if (TP + FP) != 0 else 0
        recall = TP / (TP + FN) if (TP + FN) != 0 else 0
        f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) != 0 else 0

        total_acc += accuracy
        total_prec += precision
        total_rec += recall
        total_f1 += f1
        count +=1
        # Display metrics for each category
        print(f"Category: {category}")
        print("--------------------------")
        print(f"True Positive: {TP}")
        print(f"False Positive: {FP}")
        print(f"False Negative: {FN}")
        print(f"True Negative: {TN}")
        print(f"Total samples: {total}\n")

        print(f"Accuracy: {accuracy:.2f}")
        print(f"Precision: {precision:.2f}")
        print(f"Recall: {recall:.2f}")
        print(f"F1 Score: {f1:.2f}")
        print("==========================\n")


    print(f"total: {count} total_acc: {total_acc}")

    total_acc = total_acc/count
    total_prec = total_prec/count
    total_rec = total_rec/count
    total_f1= total_f1/count

    
    # Display metrics
    print("============== MACRO AVERAGE =============")
    print(f"Accuracy: {total_acc:.2f}")
    print(f"Precision: {total_prec:.2f}")
    print(f"Recall: {total_rec:.2f}")
    print(f"F1 Score: {total_f1:.2f}")

    return conf_matrix



def compute_metrics_per_category_old(df_merged):
    # Compute the confusion matrix
    conf_matrix = confusion_matrix(df_merged['CATEGORY'], df_merged['SMELL'])
    
    # Calculate the metrics for each category
    categories = sorted(df_merged['CATEGORY'].unique())

    total_acc = 0
    total_prec = 0
    total_rec = 0
    total_f1 = 0

    count = 0
    print("\n==========================")
    for category in categories:
        if category == 'none':
            # Per la categoria 'none', contiamo gli script senza smell
            TP = len(df_merged[(df_merged['CATEGORY'] == 'none') & (df_merged['SMELL'] == 'none')])
            FP = len(df_merged[(df_merged['CATEGORY'] != 'none') & (df_merged['SMELL'] == 'none')])
            FN = len(df_merged[(df_merged['CATEGORY'] == 'none') & (df_merged['SMELL'] != 'none')])
            TN = len(df_merged[(df_merged['CATEGORY'] != 'none') & (df_merged['SMELL'] != 'none')])
        else:
            # Per le altre categorie, contiamo le righe con smell specifico
            TP = len(df_merged[(df_merged['CATEGORY'] == category) & (df_merged['SMELL'] == category)])
            FP = len(df_merged[(df_merged['CATEGORY'] != category) & (df_merged['SMELL'] == category)])
            FN = len(df_merged[(df_merged['CATEGORY'] == category) & (df_merged['SMELL'] != category)])
            TN = len(df_merged[(df_merged['CATEGORY'] != category) & (df_merged['SMELL'] != category)])

        # Compute metrics for each category
        total = TP + TN + FP + FN
        accuracy = (TP + TN) / total if total != 0 else 0
        precision = TP / (TP + FP) if (TP + FP) != 0 else 0
        recall = TP / (TP + FN) if (TP + FN) != 0 else 0
        f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) != 0 else 0

        total_acc += accuracy
        total_prec += precision
        total_rec += recall
        total_f1 += f1
        count +=1
        # Display metrics for each category
        print(f"Category: {category}")
        print("--------------------------")
        print(f"True Positive: {TP}")
        print(f"False Positive: {FP}")
        print(f"False Negative: {FN}")
        print(f"True Negative: {TN}")
        print(f"Total samples: {total}\n")

        print(f"Accuracy: {accuracy:.2f}")
        print(f"Precision: {precision:.2f}")
        print(f"Recall: {recall:.2f}")
        print(f"F1 Score: {f1:.2f}")
        print("==========================\n")


    print(f"total: {count} total_acc: {total_acc}")

    total_acc = total_acc/count
    total_prec = total_prec/count
    total_rec = total_rec/count
    total_f1= total_f1/count

    
    # Display metrics
    print("============== MACRO AVERAGE =============")
    print(f"Accuracy: {total_acc:.2f}")
    print(f"Precision: {total_prec:.2f}")
    print(f"Recall: {total_rec:.2f}")
    print(f"F1 Score: {total_f1:.2f}")

    return conf_matrix


def main():
    # Set up the argument parser
    parser = argparse.ArgumentParser(description="Compute the confusion matrix and metrics for the CSV files.")
    
    # Add arguments for the files
    parser.add_argument("smell_file", help="Path to the file with predicted labels (SMELL).")
    parser.add_argument("category_file", help="Path to the file with true categories (CATEGORY).")
    # Add argument for the output file
    parser.add_argument("--output", help="Path to save the merged CSV file.", default=None)
    
    # Parse the arguments
    args = parser.parse_args()
    
    # Load the data from the provided file paths
    df_merged = load_data(args.smell_file, args.category_file)
    
    # Compute metrics and confusion matrix    
    compute_metrics_per_category(df_merged)



    # If output path is provided, save the merged DataFrame to CSV
    if args.output:
        df_merged.to_csv(args.output, index=False)
        print(f"Merged data saved to {args.output}")

if __name__ == "__main__":
    main()
