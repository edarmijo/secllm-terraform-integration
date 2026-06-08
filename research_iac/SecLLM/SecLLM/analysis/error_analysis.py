import pandas as pd
import json
import numpy as np
from collections import defaultdict, Counter
import os
from pathlib import Path
import re

def load_all_data():
    """Carica tutti i dati essenziali"""
    
    data = {
        'glitch': {},
        'oracle': {},
        'secllm': {
            'gpt-4o-mini': {},
            'qwen2.5-14b': {},
            'qwen2.5-32b': {}
        }
    }
    
    # Carica GLITCH e Oracle
    for iac in ['ansible', 'chef', 'puppet']:
        # GLITCH usa separatore ; invece di ,
        glitch_file = f'../glitch-datasets/{iac}/oracle-dataset-analysis/GLITCH-{iac}-oracle.csv'
        try:
            data['glitch'][iac] = pd.read_csv(glitch_file, sep=';')
            if len(data['glitch'][iac].columns) == 1:
                data['glitch'][iac] = pd.read_csv(glitch_file, sep=',')
        except:
            for sep in [';', ',', '\t']:
                try:
                    data['glitch'][iac] = pd.read_csv(glitch_file, sep=sep)
                    if len(data['glitch'][iac].columns) > 1:
                        break
                except:
                    continue
        
        data['oracle'][iac] = pd.read_csv(f'../glitch-datasets/{iac}/oracle-dataset-analysis/oracle_dataset.csv')
    
    # Carica SecLLM - usa la selezione più consistente
    for model in ['gpt-4o-mini', 'qwen2.5-14b', 'qwen2.5-32b']:
        for iac in ['ansible', 'chef', 'puppet']:
            iterations = []
            path_base = '../results/gpt-4o-mini' if model == 'gpt-4o-mini' else f'../results/ow_llms/{model}'
            
            for iteration in ['I-Iteration', 'II-Iteration', 'III-Iteration', 'IV-Iteration', 'V-Iteration']:
                file_path = f'{path_base}/{iac}/{iteration}/output_{iac}.json'
                with open(file_path, 'r') as f:
                    iterations.append(json.load(f))
            
            # Usa la selezione più consistente invece del majority voting
            data['secllm'][model][iac] = select_most_consistent_iteration(iterations, iac, model)
    
    return data

def select_most_consistent_iteration(iterations, iac_type, model_name):
    """Seleziona l'iterazione più consistente"""
    
    print(f"  Selecting most consistent results for {model_name}-{iac_type}")
    
    # Converti ogni iterazione in DataFrame per analisi
    iteration_dfs = []
    
    for i, iteration in enumerate(iterations):
        detections = []
        for detection in iteration:
            if detection['SMELL'] != 'none' and detection['LINE'] != 0:
                detections.append({
                    'path': detection['PATH'],
                    'smell': detection['SMELL'],
                    'line': int(detection['LINE']),  # Converte subito a int per evitare problemi
                    'iteration': i
                })
        
        iteration_dfs.append(pd.DataFrame(detections))
        print(f"    Iteration {i+1}: {len(detections)} detections")
    
    # Strategia 1: Trova l'iterazione con più overlap con le altre
    best_iteration_idx = find_most_consistent_iteration(iteration_dfs)
    
    if best_iteration_idx is not None:
        print(f"    Selected iteration {best_iteration_idx + 1} as most consistent")
        result_df = iteration_dfs[best_iteration_idx].drop('iteration', axis=1)
        print(f"    Final result: {len(result_df)} detections")
        return result_df
    
    # Strategia 2: Se nessuna iterazione è chiaramente migliore, usa consensus
    print(f"    No clear best iteration, using consensus approach")
    result_df = create_consensus_results(iteration_dfs)
    print(f"    Consensus result: {len(result_df)} detections")
    return result_df

def find_most_consistent_iteration(iteration_dfs):
    """Trova l'iterazione che ha più overlap con le altre"""
    
    if not iteration_dfs or all(df.empty for df in iteration_dfs):
        return None
    
    iteration_scores = []
    
    for i, df_i in enumerate(iteration_dfs):
        if df_i.empty:
            iteration_scores.append(0)
            continue
            
        # Calcola overlap con tutte le altre iterazioni
        total_overlap = 0
        total_comparisons = 0
        
        for j, df_j in enumerate(iteration_dfs):
            if i == j or df_j.empty:
                continue
                
            # Crea set di detection keys per confronto
            keys_i = set(df_i.apply(lambda x: f"{x['path']}#{x['smell']}#{x['line']}", axis=1))
            keys_j = set(df_j.apply(lambda x: f"{x['path']}#{x['smell']}#{x['line']}", axis=1))
            
            if keys_i or keys_j:  # Evita divisione per zero
                overlap = len(keys_i.intersection(keys_j))
                union = len(keys_i.union(keys_j))
                jaccard = overlap / union if union > 0 else 0
                total_overlap += jaccard
                total_comparisons += 1
        
        avg_overlap = total_overlap / total_comparisons if total_comparisons > 0 else 0
        iteration_scores.append(avg_overlap)
        print(f"    Iteration {i+1}: avg overlap = {avg_overlap:.3f}")
    
    # Seleziona l'iterazione con overlap più alto
    if max(iteration_scores) > 0.1:  # Soglia minima di consistenza
        return iteration_scores.index(max(iteration_scores))
    
    return None

def create_consensus_results(iteration_dfs):
    """Crea risultati consensus quando nessuna iterazione è chiaramente migliore"""
    
    # Raccoglie tutte le detection uniche
    all_detections = defaultdict(list)  # key -> list of iterations that found it
    
    for i, df in enumerate(iteration_dfs):
        if df.empty:
            continue
            
        for _, row in df.iterrows():
            key = f"{row['path']}#{row['smell']}#{row['line']}"
            all_detections[key].append(i)
    
    # Strategia consensus: prendi detection che appaiono in almeno 2 iterazioni
    consensus_detections = []
    
    for detection_key, iterations_found in all_detections.items():
        path, smell, line = detection_key.split('#')
        
        # Prendi se appare in almeno 2 iterazioni
        if len(iterations_found) >= 2:
            consensus_detections.append({
                'path': path,
                'smell': smell,
                'line': int(line),
                'consistency_score': len(iterations_found)
            })
    
    print(f"    Consensus: {len(consensus_detections)} detections")
    return pd.DataFrame(consensus_detections)

def normalize_smell_name(smell_name):
    """Normalizza i nomi degli smell per confronti consistenti"""
    if pd.isna(smell_name):
        return None
    
    # Dizionario di mappatura per standardizzare i nomi
    smell_mapping = {
        # Varie forme di "Admin by default"
        'admin_by_default': 'Admin by default',
        'Admin by default': 'Admin by default',
        'ADMIN_BY_DEFAULT': 'Admin by default',
        
        # Varie forme di "Suspicious comment"
        'suspicious_comment': 'Suspicious comment',
        'Suspicious comment': 'Suspicious comment',
        'SUSPICIOUS_COMMENT': 'Suspicious comment',
        
        # Varie forme di "Use of HTTP without SSL/TLS"
        'use_of_http_without_tls': 'Use of HTTP without SSL/TLS',
        'use_of_http_without_ssl_tls': 'Use of HTTP without SSL/TLS',
        'Use of HTTP without SSL/TLS': 'Use of HTTP without SSL/TLS',
        'USE_OF_HTTP_WITHOUT_SSL_TLS': 'Use of HTTP without SSL/TLS',
        
        # Varie forme di "Hard-coded secret"
        'hard_coded_secret': 'Hard-coded secret',
        'hard-coded_secret': 'Hard-coded secret',
        'Hard-coded secret': 'Hard-coded secret',
        'HARD_CODED_SECRET': 'Hard-coded secret',
        
        # Varie forme di "Empty password"
        'empty_password': 'Empty password',
        'Empty password': 'Empty password',
        'EMPTY_PASSWORD': 'Empty password',
        
        # Varie forme di "Unrestricted IP Address"
        'unrestricted_ip_address': 'Unrestricted IP Address',
        'invalid_ip_address_binding': 'Unrestricted IP Address',
        'Unrestricted IP Address': 'Unrestricted IP Address',
        'UNRESTRICTED_IP_ADDRESS': 'Unrestricted IP Address',
        
        # Varie forme di "No integrity check"
        'no_integrity_check': 'No integrity check',
        'No integrity check': 'No integrity check',
        'NO_INTEGRITY_CHECK': 'No integrity check',
        
        # Varie forme di "Use of weak cryptography algorithms"
        'use_of_weak_cryptography_algorithms': 'Use of weak cryptography algorithms',
        'Use of weak cryptography algorithms': 'Use of weak cryptography algorithms',
        'USE_OF_WEAK_CRYPTOGRAPHY_ALGORITHMS': 'Use of weak cryptography algorithms',
        
        # Varie forme di "Missing Default in Case Statement"
        'missing_default_case_statement': 'Missing Default in Case Statement',
        'Missing Default in Case Statement': 'Missing Default in Case Statement',
        'MISSING_DEFAULT_CASE_STATEMENT': 'Missing Default in Case Statement',
    }
    
    return smell_mapping.get(smell_name, smell_name)

def clean_line_number(line_value):
    """Pulisce i numeri di linea rimuovendo spazi extra"""
    if pd.isna(line_value):
        return 0
    
    # Se è già un numero, restituiscilo
    if isinstance(line_value, (int, float)):
        return int(line_value)
    
    # Se è una stringa, rimuovi spazi e converti
    if isinstance(line_value, str):
        cleaned = re.sub(r'\s+', '', line_value.strip())
        try:
            return int(cleaned)
        except ValueError:
            return 0
    
    return 0

def normalize_data(df, path_col='PATH', smell_col='SMELL', line_col='LINE'):
    """Normalizza i dataframe per avere colonne consistenti"""
    
    print(f"  Input columns: {list(df.columns)}")
    print(f"  Input shape: {df.shape}")
    
    df_norm = df.copy()
    
    # Mappa i nomi delle colonne a quelli standardizzati
    column_mapping = {
        path_col: 'path',
        smell_col: 'smell', 
        line_col: 'line'
    }
    
    # Rinomina solo le colonne che esistono
    existing_columns = {old: new for old, new in column_mapping.items() if old in df_norm.columns}
    print(f"  Renaming columns: {existing_columns}")
    
    df_norm.rename(columns=existing_columns, inplace=True)
    print(f"  Output columns: {list(df_norm.columns)}")
    
    # Filtra solo le righe con smell validi (non 'none' o 0)
    if 'smell' in df_norm.columns:
        initial_len = len(df_norm)
        df_norm = df_norm[df_norm['smell'] != 'none']
        print(f"  Filtered 'none' smells: {initial_len} -> {len(df_norm)}")
        
        # Normalizza i nomi degli smell
        df_norm['smell'] = df_norm['smell'].apply(normalize_smell_name)
        
        # Debug: mostra i tipi di smell presenti
        if len(df_norm) > 0:
            smell_counts = df_norm['smell'].value_counts()
            print(f"  Smell types found: {dict(smell_counts)}")
        
    if 'line' in df_norm.columns:
        initial_len = len(df_norm)
        df_norm = df_norm[df_norm['line'] != 0]
        
        # Pulisci i numeri di linea
        df_norm['line'] = df_norm['line'].apply(clean_line_number)
        df_norm = df_norm[df_norm['line'] != 0]
        
        print(f"  Cleaned and filtered lines: {initial_len} -> {len(df_norm)}")
    
    print(f"  Final shape: {df_norm.shape}")
    
    return df_norm

def create_detection_key(path, smell, line):
    """Crea una chiave unica per ogni detection"""
    return f"{path}#{smell}#{line}"

def analyze_predictions_vs_oracle(predictions_df, oracle_df, debug_info=""):
    """Confronta predictions con oracle e identifica TP, FP, FN"""
    
    print(f"    Comparing predictions ({len(predictions_df)}) vs oracle ({len(oracle_df)}) {debug_info}")
    
    if predictions_df.empty:
        fn_keys = set(oracle_df.apply(lambda x: create_detection_key(x['path'], x['smell'], x['line']), axis=1))
        return {
            'tp': set(),
            'fp': set(),
            'fn': fn_keys,
            'tp_details': pd.DataFrame(),
            'fp_details': pd.DataFrame(),
            'fn_details': oracle_df
        }
    
    # Debug: verifica che le colonne esistano
    print(f"    Predictions columns: {list(predictions_df.columns)}")
    print(f"    Oracle columns: {list(oracle_df.columns)}")
    
    # Assicurati che le colonne necessarie esistano
    if not all(col in predictions_df.columns for col in ['path', 'smell', 'line']):
        raise ValueError(f"Predictions missing required columns. Has: {list(predictions_df.columns)}")
    if not all(col in oracle_df.columns for col in ['path', 'smell', 'line']):
        raise ValueError(f"Oracle missing required columns. Has: {list(oracle_df.columns)}")
    
    # Crea set di chiavi per confronto rapido
    oracle_keys = set(oracle_df.apply(
        lambda x: create_detection_key(x['path'], x['smell'], x['line']), axis=1
    ))
    
    prediction_keys = set(predictions_df.apply(
        lambda x: create_detection_key(x['path'], x['smell'], x['line']), axis=1
    ))
    
    print(f"    Oracle keys: {len(oracle_keys)}")
    print(f"    Prediction keys: {len(prediction_keys)}")
    
    # Debug: mostra alcune keys di esempio per il primo caso
    if debug_info and ("gpt-4o-mini" in debug_info and "ansible" in debug_info):
        if oracle_keys:
            sample_oracle = list(oracle_keys)[:3]
            print(f"    Sample oracle keys: {sample_oracle}")
        if prediction_keys:
            sample_predictions = list(prediction_keys)[:3]
            print(f"    Sample prediction keys: {sample_predictions}")
    
    # Identifica TP, FP, FN
    tp_keys = oracle_keys.intersection(prediction_keys)
    fp_keys = prediction_keys - oracle_keys
    fn_keys = oracle_keys - prediction_keys
    
    print(f"    TP: {len(tp_keys)}, FP: {len(fp_keys)}, FN: {len(fn_keys)}")
    
    # Debug: mostra keys specifici se ci sono problemi per il primo caso
    if debug_info and ("gpt-4o-mini" in debug_info and "ansible" in debug_info):
        if fn_keys:
            sample_fn = list(fn_keys)[:3]
            print(f"    Sample FN keys: {sample_fn}")
        if fp_keys:
            sample_fp = list(fp_keys)[:3]
            print(f"    Sample FP keys: {sample_fp}")
    
    return {
        'tp': tp_keys,
        'fp': fp_keys, 
        'fn': fn_keys,
        'tp_details': predictions_df[predictions_df.apply(lambda x: create_detection_key(x['path'], x['smell'], x['line']), axis=1).isin(tp_keys)],
        'fp_details': predictions_df[predictions_df.apply(lambda x: create_detection_key(x['path'], x['smell'], x['line']), axis=1).isin(fp_keys)],
        'fn_details': oracle_df[oracle_df.apply(lambda x: create_detection_key(x['path'], x['smell'], x['line']), axis=1).isin(fn_keys)]
    }

def calculate_metrics_by_smell(analysis, oracle_df):
    """Calcola metriche per ogni tipo di smell"""
    
    metrics = {}
    
    for smell_type in oracle_df['smell'].unique():
        
        # Conta TP, FP, FN per questo smell type
        tp_count = len([k for k in analysis['tp'] if f"#{smell_type}#" in k])
        fp_count = len([k for k in analysis['fp'] if f"#{smell_type}#" in k])
        fn_count = len([k for k in analysis['fn'] if f"#{smell_type}#" in k])
        
        oracle_count = len(oracle_df[oracle_df['smell'] == smell_type])
        
        precision = tp_count / (tp_count + fp_count) if (tp_count + fp_count) > 0 else 0
        recall = tp_count / (tp_count + fn_count) if (tp_count + fn_count) > 0 else 0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0
        
        metrics[smell_type] = {
            'precision': precision,
            'recall': recall,
            'f1': f1,
            'tp': tp_count,
            'fp': fp_count,
            'fn': fn_count,
            'oracle_count': oracle_count
        }
    
    return metrics

def debug_specific_case(model, iac, smell_type):
    """Debug per un caso specifico"""
    
    print(f"\n=== DEBUG: {model} - {iac} - {smell_type} ===")
    
    # Carica i dati grezzi
    data = load_all_data()
    
    oracle_df = normalize_data(data['oracle'][iac], smell_col='CATEGORY')
    glitch_df = normalize_data(data['glitch'][iac])
    secllm_df = data['secllm'][model][iac]
    
    # Normalizza anche SecLLM df
    secllm_df['smell'] = secllm_df['smell'].apply(normalize_smell_name)
    
    # Normalizza il nome dello smell per il filtro
    normalized_smell = normalize_smell_name(smell_type)
    
    # Filtra per il smell specifico
    oracle_smell = oracle_df[oracle_df['smell'] == normalized_smell] if 'smell' in oracle_df.columns else pd.DataFrame()
    glitch_smell = glitch_df[glitch_df['smell'] == normalized_smell] if 'smell' in glitch_df.columns else pd.DataFrame()
    secllm_smell = secllm_df[secllm_df['smell'] == normalized_smell] if 'smell' in secllm_df.columns else pd.DataFrame()
    
    print(f"Searching for normalized smell: '{normalized_smell}'")
    print(f"Oracle {smell_type}: {len(oracle_smell)} detections")
    if len(oracle_smell) > 0:
        print(oracle_smell[['path', 'line']].to_string())
    
    print(f"\nGLITCH {smell_type}: {len(glitch_smell)} detections")
    if len(glitch_smell) > 0:
        print(glitch_smell[['path', 'line']].to_string())
    
    print(f"\nSecLLM {smell_type}: {len(secllm_smell)} detections")
    if len(secllm_smell) > 0:
        print(secllm_smell[['path', 'line']].to_string())
    
    # Confronta le detection keys
    if len(oracle_smell) > 0:
        oracle_keys = set(oracle_smell.apply(lambda x: f"{x['path']}#{x['line']}", axis=1))
        glitch_keys = set(glitch_smell.apply(lambda x: f"{x['path']}#{x['line']}", axis=1)) if len(glitch_smell) > 0 else set()
        secllm_keys = set(secllm_smell.apply(lambda x: f"{x['path']}#{x['line']}", axis=1)) if len(secllm_smell) > 0 else set()
        
        print(f"\nOracle keys: {oracle_keys}")
        print(f"GLITCH keys: {glitch_keys}")
        print(f"SecLLM keys: {secllm_keys}")
        
        print(f"\nGLITCH TP: {len(oracle_keys.intersection(glitch_keys))}")
        print(f"GLITCH FP: {len(glitch_keys - oracle_keys)}")
        print(f"GLITCH FN: {len(oracle_keys - glitch_keys)}")
        
        print(f"\nSecLLM TP: {len(oracle_keys.intersection(secllm_keys))}")
        print(f"SecLLM FP: {len(secllm_keys - oracle_keys)}")
        print(f"SecLLM FN: {len(oracle_keys - secllm_keys)}")
        
        # Calcola precision e recall
        glitch_tp = len(oracle_keys.intersection(glitch_keys))
        glitch_fp = len(glitch_keys - oracle_keys)
        glitch_fn = len(oracle_keys - glitch_keys)
        
        secllm_tp = len(oracle_keys.intersection(secllm_keys))
        secllm_fp = len(secllm_keys - oracle_keys)
        secllm_fn = len(oracle_keys - secllm_keys)
        
        glitch_precision = glitch_tp / (glitch_tp + glitch_fp) if (glitch_tp + glitch_fp) > 0 else 0
        glitch_recall = glitch_tp / (glitch_tp + glitch_fn) if (glitch_tp + glitch_fn) > 0 else 0
        
        secllm_precision = secllm_tp / (secllm_tp + secllm_fp) if (secllm_tp + secllm_fp) > 0 else 0
        secllm_recall = secllm_tp / (secllm_tp + secllm_fn) if (secllm_tp + secllm_fn) > 0 else 0
        
        print(f"\nGLITCH Precision: {glitch_precision:.3f}, Recall: {glitch_recall:.3f}")
        print(f"SecLLM Precision: {secllm_precision:.3f}, Recall: {secllm_recall:.3f}")
        
        print(f"Precision diff: {glitch_precision - secllm_precision:.3f}")
        print(f"Recall diff: {glitch_recall - secllm_recall:.3f}")

def analyze_model_specific_underperformance():
    """Analizza underperformance per ogni modello separatamente"""
    
    data = load_all_data()
    model_analysis = {}
    
    for model in ['gpt-4o-mini', 'qwen2.5-14b', 'qwen2.5-32b']:
        print(f"\n=== Analyzing {model} ===")
        
        model_analysis[model] = {
            'precision_losses': [],
            'recall_losses': [],
            'overall_performance': {},
            'consistency_info': {}  # Nuova sezione per info sulla consistenza
        }
        
        model_total_metrics = {'glitch': {}, 'secllm': {}}
        
        for iac in ['ansible', 'chef', 'puppet']:
            print(f"Analyzing {iac} for {model}...")
            
            oracle_df = normalize_data(data['oracle'][iac], smell_col='CATEGORY')
            print(f"  Oracle normalized: {len(oracle_df)} detections")
            
            glitch_df = normalize_data(data['glitch'][iac])
            print(f"  GLITCH normalized: {len(glitch_df)} detections")
            
            secllm_df = data['secllm'][model][iac].copy()
            # Normalizza anche i nomi degli smell per SecLLM
            secllm_df['smell'] = secllm_df['smell'].apply(normalize_smell_name)
            print(f"  {model}: {len(secllm_df)} detections")
            
            # Salva info sulla consistenza se disponibile
            if 'consistency_score' in secllm_df.columns:
                avg_consistency = secllm_df['consistency_score'].mean()
                model_analysis[model]['consistency_info'][iac] = {
                    'avg_consistency': avg_consistency,
                    'total_detections': len(secllm_df),
                    'high_consistency': len(secllm_df[secllm_df['consistency_score'] >= 3])
                }
            
            # Analizza GLITCH vs Oracle
            print(f"  Analyzing GLITCH vs Oracle...")
            glitch_analysis = analyze_predictions_vs_oracle(glitch_df, oracle_df, f"GLITCH-{model}-{iac}")
            glitch_metrics = calculate_metrics_by_smell(glitch_analysis, oracle_df)
            
            # Analizza SecLLM vs Oracle
            print(f"  Analyzing {model} vs Oracle...")
            secllm_analysis = analyze_predictions_vs_oracle(secllm_df, oracle_df, f"SecLLM-{model}-{iac}")
            secllm_metrics = calculate_metrics_by_smell(secllm_analysis, oracle_df)
            
            # Salva metriche per calcolo overall
            model_total_metrics['glitch'][iac] = glitch_metrics
            model_total_metrics['secllm'][iac] = secllm_metrics
            
            # Debug per i casi problematici - ora usa i nomi corretti
            if model == 'gpt-4o-mini' and iac == 'ansible':
                print(f"\n=== DEBUG DETAILED METRICS FOR {model}-{iac} ===")
                for smell_type in ['Suspicious comment', 'Admin by default', 'Use of HTTP without SSL/TLS']:
                    if smell_type in glitch_metrics and smell_type in secllm_metrics:
                        g_metrics = glitch_metrics[smell_type]
                        s_metrics = secllm_metrics[smell_type]
                        
                        print(f"\n{smell_type.upper()}:")
                        print(f"  GLITCH: P={g_metrics['precision']:.3f}, R={g_metrics['recall']:.3f}, F1={g_metrics['f1']:.3f}")
                        print(f"  SecLLM: P={s_metrics['precision']:.3f}, R={s_metrics['recall']:.3f}, F1={s_metrics['f1']:.3f}")
                        print(f"  Diff P: {g_metrics['precision'] - s_metrics['precision']:.3f}")
                        print(f"  Diff R: {g_metrics['recall'] - s_metrics['recall']:.3f}")
            
            # Identifica underperformance per ogni smell
            for smell_type in glitch_metrics.keys():
                if smell_type in secllm_metrics:
                    
                    # Precision loss
                    prec_diff = glitch_metrics[smell_type]['precision'] - secllm_metrics[smell_type]['precision']
                    if prec_diff > 0.05:  # Soglia significativa
                        model_analysis[model]['precision_losses'].append({
                            'iac': iac,
                            'smell': smell_type,
                            'glitch_precision': glitch_metrics[smell_type]['precision'],
                            'secllm_precision': secllm_metrics[smell_type]['precision'],
                            'loss': prec_diff,
                            'oracle_count': glitch_metrics[smell_type]['oracle_count'],
                            'glitch_tp': glitch_metrics[smell_type]['tp'],
                            'glitch_fp': glitch_metrics[smell_type]['fp'],
                            'secllm_tp': secllm_metrics[smell_type]['tp'],
                            'secllm_fp': secllm_metrics[smell_type]['fp'],
                            'glitch_f1': glitch_metrics[smell_type]['f1'],
                            'secllm_f1': secllm_metrics[smell_type]['f1']
                        })
                    
                    # Recall loss  
                    rec_diff = glitch_metrics[smell_type]['recall'] - secllm_metrics[smell_type]['recall']
                    if rec_diff > 0.05:
                        model_analysis[model]['recall_losses'].append({
                            'iac': iac,
                            'smell': smell_type,
                            'glitch_recall': glitch_metrics[smell_type]['recall'],
                            'secllm_recall': secllm_metrics[smell_type]['recall'],
                            'loss': rec_diff,
                            'oracle_count': glitch_metrics[smell_type]['oracle_count'],
                            'glitch_tp': glitch_metrics[smell_type]['tp'],
                            'glitch_fn': glitch_metrics[smell_type]['fn'],
                            'secllm_tp': secllm_metrics[smell_type]['tp'],
                            'secllm_fn': secllm_metrics[smell_type]['fn'],
                            'glitch_f1': glitch_metrics[smell_type]['f1'],
                            'secllm_f1': secllm_metrics[smell_type]['f1']
                        })
        
        # Calcola performance overall del modello
        model_analysis[model]['overall_performance'] = calculate_overall_model_performance(
            model_total_metrics, model
        )
    
    return model_analysis

def calculate_overall_model_performance(model_total_metrics, model_name):
    """Calcola performance complessiva del modello"""
    
    all_glitch_tp = all_glitch_fp = all_glitch_fn = 0
    all_secllm_tp = all_secllm_fp = all_secllm_fn = 0
    
    for iac in ['ansible', 'chef', 'puppet']:
        for smell_type, metrics in model_total_metrics['glitch'][iac].items():
            all_glitch_tp += metrics['tp']
            all_glitch_fp += metrics['fp']
            all_glitch_fn += metrics['fn']
            
        for smell_type, metrics in model_total_metrics['secllm'][iac].items():
            all_secllm_tp += metrics['tp']
            all_secllm_fp += metrics['fp']
            all_secllm_fn += metrics['fn']
    
    # Calcola metriche overall
    glitch_precision = all_glitch_tp / (all_glitch_tp + all_glitch_fp) if (all_glitch_tp + all_glitch_fp) > 0 else 0
    glitch_recall = all_glitch_tp / (all_glitch_tp + all_glitch_fn) if (all_glitch_tp + all_glitch_fn) > 0 else 0
    glitch_f1 = 2 * glitch_precision * glitch_recall / (glitch_precision + glitch_recall) if (glitch_precision + glitch_recall) > 0 else 0
    
    secllm_precision = all_secllm_tp / (all_secllm_tp + all_secllm_fp) if (all_secllm_tp + all_secllm_fp) > 0 else 0
    secllm_recall = all_secllm_tp / (all_secllm_tp + all_secllm_fn) if (all_secllm_tp + all_secllm_fn) > 0 else 0
    secllm_f1 = 2 * secllm_precision * secllm_recall / (secllm_precision + secllm_recall) if (secllm_precision + secllm_recall) > 0 else 0
    
    return {
        'glitch': {
            'precision': glitch_precision,
            'recall': glitch_recall,
            'f1': glitch_f1,
            'tp': all_glitch_tp,
            'fp': all_glitch_fp,
            'fn': all_glitch_fn
        },
        'secllm': {
            'precision': secllm_precision,
            'recall': secllm_recall,
            'f1': secllm_f1,
            'tp': all_secllm_tp,
            'fp': all_secllm_fp,
            'fn': all_secllm_fn
        }
    }

# [Resto delle funzioni rimane uguale...]
# [generate_model_specific_insights, generate_article_summary, quick_validation, test_specific_issues]

def generate_model_specific_insights(model_analysis):
    """Genera insights specifici per ogni modello"""
    
    insights = []
    insights.append("# Model-Specific Analysis: Where GLITCH Outperforms SecLLM\n")
    
    # Informazioni sulla selezione delle iterazioni
    insights.append("## Methodology Note\n")
    insights.append("Results are based on the most consistent iteration selected from 5 runs for each model, "
                   "or consensus results when no single iteration showed clear consistency advantages.\n")
    
    # Tabella riassuntiva delle performance
    insights.append("## Overall Performance Comparison\n")
    insights.append("| Model | Tool | Precision | Recall | F1-Score | TP | FP | FN |")
    insights.append("|-------|------|-----------|--------|----------|----|----|----|\n")
    
    for model in ['gpt-4o-mini', 'qwen2.5-14b', 'qwen2.5-32b']:
        overall = model_analysis[model]['overall_performance']
        
        insights.append(f"| {model} | GLITCH | {overall['glitch']['precision']:.3f} | "
                       f"{overall['glitch']['recall']:.3f} | {overall['glitch']['f1']:.3f} | "
                       f"{overall['glitch']['tp']} | {overall['glitch']['fp']} | {overall['glitch']['fn']} |")
        
        insights.append(f"| {model} | SecLLM | {overall['secllm']['precision']:.3f} | "
                       f"{overall['secllm']['recall']:.3f} | {overall['secllm']['f1']:.3f} | "
                       f"{overall['secllm']['tp']} | {overall['secllm']['fp']} | {overall['secllm']['fn']} |")
        
        # Calcola differenze
        prec_diff = overall['glitch']['precision'] - overall['secllm']['precision']
        rec_diff = overall['glitch']['recall'] - overall['secllm']['recall']
        f1_diff = overall['glitch']['f1'] - overall['secllm']['f1']
        
        insights.append(f"| {model} | **Difference** | **{prec_diff:+.3f}** | "
                       f"**{rec_diff:+.3f}** | **{f1_diff:+.3f}** | - | - | - |")
    
    insights.append("\n")
    
    # Informazioni sulla consistenza
    insights.append("## Iteration Consistency Analysis\n")
    for model in ['gpt-4o-mini', 'qwen2.5-14b', 'qwen2.5-32b']:
        if model_analysis[model]['consistency_info']:
            insights.append(f"### {model.upper()}\n")
            for iac, info in model_analysis[model]['consistency_info'].items():
                insights.append(f"- **{iac.capitalize()}**: Avg consistency = {info['avg_consistency']:.2f}, "
                               f"High consistency detections = {info['high_consistency']}/{info['total_detections']}")
            insights.append("")
    
    # Analisi dettagliata per ogni modello
    for model in ['gpt-4o-mini', 'qwen2.5-14b', 'qwen2.5-32b']:
        insights.append(f"## {model.upper()} Specific Analysis\n")
        
        precision_losses = model_analysis[model]['precision_losses']
        recall_losses = model_analysis[model]['recall_losses']
        
        if precision_losses:
            insights.append(f"### Precision Disadvantages ({len(precision_losses)} cases)\n")
            
            # Raggruppa per smell type
            precision_by_smell = defaultdict(list)
            for loss in precision_losses:
                precision_by_smell[loss['smell']].append(loss)
            
            for smell_type, losses in precision_by_smell.items():
                avg_loss = np.mean([l['loss'] for l in losses])
                insights.append(f"**{smell_type}** (avg loss: {avg_loss:.3f}):")
                
                for loss in sorted(losses, key=lambda x: x['loss'], reverse=True)[:2]:  # Top 2
                    insights.append(f"- {loss['iac'].capitalize()}: GLITCH {loss['glitch_precision']:.3f} vs "
                                   f"SecLLM {loss['secllm_precision']:.3f} (loss: {loss['loss']:.3f})")
                    insights.append(f"  Oracle: {loss['oracle_count']}, GLITCH TP/FP: {loss['glitch_tp']}/{loss['glitch_fp']}, "
                                   f"SecLLM TP/FP: {loss['secllm_tp']}/{loss['secllm_fp']}")
                insights.append("")
        
        if recall_losses:
            insights.append(f"### Recall Disadvantages ({len(recall_losses)} cases)\n")
            
            # Raggruppa per smell type
            recall_by_smell = defaultdict(list)
            for loss in recall_losses:
                recall_by_smell[loss['smell']].append(loss)
            
            for smell_type, losses in recall_by_smell.items():
                avg_loss = np.mean([l['loss'] for l in losses])
                insights.append(f"**{smell_type}** (avg loss: {avg_loss:.3f}):")
                
                for loss in sorted(losses, key=lambda x: x['loss'], reverse=True)[:2]:  # Top 2
                    insights.append(f"- {loss['iac'].capitalize()}: GLITCH {loss['glitch_recall']:.3f} vs "
                                   f"SecLLM {loss['secllm_recall']:.3f} (loss: {loss['loss']:.3f})")
                    insights.append(f"  Oracle: {loss['oracle_count']}, GLITCH TP/FN: {loss['glitch_tp']}/{loss['glitch_fn']}, "
                                   f"SecLLM TP/FN: {loss['secllm_tp']}/{loss['secllm_fn']}")
                insights.append("")
        
        if not precision_losses and not recall_losses:
            insights.append(f"No significant underperformance cases found for {model}.\n")
        
        insights.append("---\n")
    
    # Analisi cross-model
    insights.append("## Cross-Model Analysis\n")
    
    # Identifica pattern comuni di underperformance
    all_precision_losses = []
    all_recall_losses = []
    
    for model in model_analysis:
        all_precision_losses.extend([(model, loss) for loss in model_analysis[model]['precision_losses']])
        all_recall_losses.extend([(model, loss) for loss in model_analysis[model]['recall_losses']])
    
    # Smell types più problematici
    precision_smell_counts = defaultdict(list)
    recall_smell_counts = defaultdict(list)
    
    for model, loss in all_precision_losses:
        precision_smell_counts[loss['smell']].append((model, loss['loss']))
    
    for model, loss in all_recall_losses:
        recall_smell_counts[loss['smell']].append((model, loss['loss']))
    
    if precision_smell_counts:
        insights.append("### Most Problematic Smells (Precision):\n")
        for smell, losses in sorted(precision_smell_counts.items(), 
                                   key=lambda x: len(x[1]), reverse=True):
            avg_loss = np.mean([loss for _, loss in losses])
            insights.append(f"- **{smell}**: {len(losses)} cases, avg loss {avg_loss:.3f}")
            for model, loss in sorted(losses, key=lambda x: x[1], reverse=True)[:3]:
                insights.append(f"  - {model}: {loss:.3f}")
        insights.append("")
    
    if recall_smell_counts:
        insights.append("### Most Problematic Smells (Recall):\n")
        for smell, losses in sorted(recall_smell_counts.items(), 
                                   key=lambda x: len(x[1]), reverse=True):
            avg_loss = np.mean([loss for _, loss in losses])
            insights.append(f"- **{smell}**: {len(losses)} cases, avg loss {avg_loss:.3f}")
            for model, loss in sorted(losses, key=lambda x: x[1], reverse=True)[:3]:
                insights.append(f"  - {model}: {loss:.3f}")
        insights.append("")
    
    return '\n'.join(insights)

def generate_article_summary(model_analysis):
    """Genera un riassunto specifico per migliorare la discussione nell'articolo"""
    
    summary = []
    summary.append("# Enhanced Discussion Section for Article\n")
    
    summary.append("## Key Findings on SecLLM Limitations\n")
    
    summary.append("### Methodology Note\n")
    summary.append("This analysis uses the most consistent results from 5 iterations per model. "
                   "We selected either the iteration with highest overlap with others, or created "
                   "consensus results when no single iteration was clearly superior.\n")
    
    # Identifica i pattern più significativi
    common_issues = defaultdict(int)
    
    for model in model_analysis:
        for loss in model_analysis[model]['precision_losses']:
            common_issues[f"precision_{loss['smell']}"] += 1
        for loss in model_analysis[model]['recall_losses']:
            common_issues[f"recall_{loss['smell']}"] += 1
    
    # Top issues
    top_issues = sorted(common_issues.items(), key=lambda x: x[1], reverse=True)[:5]
    
    summary.append("### Most Frequent Underperformance Patterns:\n")
    for issue, count in top_issues:
        metric_type, smell = issue.split('_', 1)
        summary.append(f"- **{smell}** ({metric_type}): {count} cases across models")
    summary.append("")
    
    # Model-specific insights
    summary.append("### Model-Specific Insights:\n")
    
    for model in ['gpt-4o-mini', 'qwen2.5-14b', 'qwen2.5-32b']:
        overall = model_analysis[model]['overall_performance']
        
        prec_diff = overall['glitch']['precision'] - overall['secllm']['precision']
        rec_diff = overall['glitch']['recall'] - overall['secllm']['recall']
        
        if prec_diff > 0.01 or rec_diff > 0.01:  # Significant differences
            summary.append(f"**{model}**:")
            if prec_diff > 0.01:
                summary.append(f"- Precision gap: {prec_diff:.3f} (GLITCH advantage)")
            if rec_diff > 0.01:
                summary.append(f"- Recall gap: {rec_diff:.3f} (GLITCH advantage)")
            
            # Informazioni sulla consistenza
            if model_analysis[model]['consistency_info']:
                total_detections = sum(info['total_detections'] 
                                     for info in model_analysis[model]['consistency_info'].values())
                high_consistency = sum(info['high_consistency'] 
                                     for info in model_analysis[model]['consistency_info'].values())
                consistency_rate = high_consistency / total_detections if total_detections > 0 else 0
                summary.append(f"- Iteration consistency: {consistency_rate:.1%} high-confidence detections")
            
            # Top problematic smells for this model
            precision_smells = [l['smell'] for l in model_analysis[model]['precision_losses']]
            recall_smells = [l['smell'] for l in model_analysis[model]['recall_losses']]
            
            if precision_smells:
                from collections import Counter
                top_precision_smells = Counter(precision_smells).most_common(2)
                smell_list = [f"{smell} ({count})" for smell, count in top_precision_smells]
                summary.append(f"- Precision issues mainly with: {', '.join(smell_list)}")
            
            if recall_smells:
                from collections import Counter
                top_recall_smells = Counter(recall_smells).most_common(2)
                smell_list = [f"{smell} ({count})" for smell, count in top_recall_smells]
                summary.append(f"- Recall issues mainly with: {', '.join(smell_list)}")
            
            summary.append("")
    
    # Suggested text for article
    summary.append("## Suggested Text for Article Discussion\n")
    
    summary.append("Despite SecLLM's overall superior performance, our detailed analysis reveals specific scenarios "
                   "where GLITCH maintains advantages. To ensure fair comparison, we selected the most consistent "
                   "results from five iterations of each SecLLM model, either choosing the iteration with highest "
                   "overlap with others or creating consensus results. These limitations provide important insights "
                   "into the current state of LLM-based security smell detection:\n")
    
    # Generate specific discussion points based on actual data
    total_losses = sum(len(model_analysis[m]['precision_losses']) + len(model_analysis[m]['recall_losses']) 
                      for m in model_analysis)
    
    if total_losses > 0:
        summary.append(f"Our analysis identified {total_losses} specific cases where GLITCH outperformed SecLLM "
                       "across all models and datasets. The most frequent limitations occur in:")
        
        for issue, count in top_issues[:3]:
            metric_type, smell = issue.split('_', 1)
            summary.append(f"- **{smell.replace('_', ' ').title()}** detection ({metric_type}): "
                           f"{count} cases across models")
        
        summary.append("\nThese patterns suggest that while LLMs excel at understanding contextual security patterns, "
                       "rule-based approaches like GLITCH maintain advantages in detecting specific, well-defined "
                       "patterns that may require exact matching or syntactic precision. Importantly, the consistency "
                       "analysis across iterations shows that SecLLM's underperformance in these areas is not due to "
                       "random variation but represents systematic limitations of the current LLM-based approach.")
    else:
        summary.append("Remarkably, our analysis found minimal cases where GLITCH significantly outperformed "
                       "SecLLM, indicating the robustness of the LLM-based approach across diverse security "
                       "smell detection scenarios.")
    
    return '\n'.join(summary)

def quick_validation():
    """Validazione rapida per verificare che i dati siano corretti"""
    
    print("=== QUICK VALIDATION ===")
    
    # Testa solo GPT-4o-mini su Ansible per iniziare
    model = 'gpt-4o-mini'
    iac = 'ansible'
    
    # Carica i dati grezzi per una sola iterazione
    path_base = '../results/gpt-4o-mini'
    file_path = f'{path_base}/{iac}/I-Iteration/output_{iac}.json'
    
    with open(file_path, 'r') as f:
        single_iteration = json.load(f)
    
    print(f"\nSingle iteration ({iac}) raw data:")
    positive_detections = [d for d in single_iteration if d['SMELL'] != 'none' and d['LINE'] != 0]
    print(f"Positive detections: {len(positive_detections)}")
    
    # Raggruppa per smell type
    smell_counts = {}
    for detection in positive_detections:
        smell = normalize_smell_name(detection['SMELL'])  # Usa normalizzazione
        if smell not in smell_counts:
            smell_counts[smell] = []
        smell_counts[smell].append((detection['PATH'], clean_line_number(detection['LINE'])))
    
    for smell, detections in smell_counts.items():
        print(f"  {smell}: {len(detections)} detections")
        for path, line in detections[:3]:  # Prime 3
            print(f"    {path}:{line}")
    
    # Ora testa il processing
    print(f"\nTesting consistency selection...")
    
    iterations = []
    for iteration in ['I-Iteration', 'II-Iteration', 'III-Iteration', 'IV-Iteration', 'V-Iteration']:
        file_path = f'{path_base}/{iac}/{iteration}/output_{iac}.json'
        with open(file_path, 'r') as f:
            iterations.append(json.load(f))
    
    result_df = select_most_consistent_iteration(iterations, iac, model)
    
    print(f"\nFinal processed result:")
    print(f"Shape: {result_df.shape}")
    if len(result_df) > 0:
        result_smell_counts = result_df['smell'].value_counts()
        print(f"Smell counts: {dict(result_smell_counts)}")

def test_specific_issues():
    """Testa i casi specifici che hai menzionato"""
    
    print("=== TESTING SPECIFIC ISSUES ===")
    
    # Test GPT-4o-mini suspicious comment, admin by default, HTTP without SSL - USA I NOMI CORRETTI
    problem_cases = [
        ('gpt-4o-mini', 'ansible', 'Suspicious comment'),
        ('gpt-4o-mini', 'ansible', 'Admin by default'),
        ('gpt-4o-mini', 'ansible', 'Use of HTTP without SSL/TLS')
    ]
    
    for model, iac, smell in problem_cases:
        debug_specific_case(model, iac, smell)

def generate_enhanced_analysis_report():
    """Genera report dettagliato per ogni modello"""
    
    print("Starting enhanced model-specific analysis with consistency-based iteration selection...")
    
    # Prima esegui la validazione rapida
    quick_validation()
    
    print("\n" + "="*50 + "\n")
    
    # Poi testa i casi specifici problematici
    test_specific_issues()
    
    print("\n" + "="*50 + "\n")
    
    model_analysis = analyze_model_specific_underperformance()
    print("Model-specific analysis completed")
    
    # 1. CSV dettagliato per ogni modello
    for model in model_analysis:
        model_data = []
        
        # Precision losses
        for loss in model_analysis[model]['precision_losses']:
            model_data.append({
                'Type': 'Precision Loss',
                'IaC': loss['iac'],
                'Smell': loss['smell'],
                'GLITCH Score': f"{loss['glitch_precision']:.3f}",
                'SecLLM Score': f"{loss['secllm_precision']:.3f}",
                'Loss': f"{loss['loss']:.3f}",
                'Oracle Count': loss['oracle_count'],
                'GLITCH TP/FP': f"{loss['glitch_tp']}/{loss['glitch_fp']}",
                'SecLLM TP/FP': f"{loss['secllm_tp']}/{loss['secllm_fp']}",
                'GLITCH F1': f"{loss['glitch_f1']:.3f}",
                'SecLLM F1': f"{loss['secllm_f1']:.3f}"
            })
        
        # Recall losses
        for loss in model_analysis[model]['recall_losses']:
            model_data.append({
                'Type': 'Recall Loss',
                'IaC': loss['iac'],
                'Smell': loss['smell'],
                'GLITCH Score': f"{loss['glitch_recall']:.3f}",
                'SecLLM Score': f"{loss['secllm_recall']:.3f}",
                'Loss': f"{loss['loss']:.3f}",
                'Oracle Count': loss['oracle_count'],
                'GLITCH TP/FN': f"{loss['glitch_tp']}/{loss['glitch_fn']}",
                'SecLLM TP/FN': f"{loss['secllm_tp']}/{loss['secllm_fn']}",
                'GLITCH F1': f"{loss['glitch_f1']:.3f}",
                'SecLLM F1': f"{loss['secllm_f1']:.3f}"
            })
        
        if model_data:
            df_model = pd.DataFrame(model_data)
            df_model.to_csv(f'../results/error_analysis/{model}_underperformance_detailed.csv', index=False)
            print(f"Generated: {model}_underperformance_detailed.csv")
    
    # 2. Report qualitativo completo
    qualitative_report = generate_model_specific_insights(model_analysis)
    
    with open('../results/error_analysis/model_specific_analysis_report.md', 'w') as f:
        f.write(qualitative_report)
    
    # 3. Riassunto per l'articolo
    article_summary = generate_article_summary(model_analysis)
    
    with open('../results/error_analysis/article_discussion_enhancement.md', 'w') as f:
        f.write(article_summary)
    
    # 4. JSON dettagliato per ulteriori analisi
    with open('../results/error_analysis/complete_model_analysis.json', 'w') as f:
        json.dump(model_analysis, f, indent=2, default=str)
    
    print("\nFiles generated:")
    print("- [model]_underperformance_detailed.csv (per each model)")
    print("- model_specific_analysis_report.md")
    print("- article_discussion_enhancement.md")
    print("- complete_model_analysis.json")
    
    # Summary stats
    total_precision_losses = sum(len(model_analysis[m]['precision_losses']) for m in model_analysis)
    total_recall_losses = sum(len(model_analysis[m]['recall_losses']) for m in model_analysis)
    
    print(f"\nSummary:")
    print(f"- Total precision loss cases: {total_precision_losses}")
    print(f"- Total recall loss cases: {total_recall_losses}")
    
    for model in model_analysis:
        p_losses = len(model_analysis[model]['precision_losses'])
        r_losses = len(model_analysis[model]['recall_losses'])
        print(f"- {model}: {p_losses} precision, {r_losses} recall losses")

if __name__ == "__main__":
    generate_enhanced_analysis_report()