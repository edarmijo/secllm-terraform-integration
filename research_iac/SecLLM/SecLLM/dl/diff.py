import os
import difflib
from fuzzywuzzy import fuzz

# Testo da confrontare
testo_script = """ template '/path/to/config/file' do
   source 'config.erb'
   variables(
     :dbuser => node['wordpress']['db']['dbuser'],
     :dbpassword => node['wordpress']['db']['dbpassword']
   )
 end
 mysql_database_user node['wordpress']['db']['dbuser'] do
   password node['wordpress']['db']['dbpassword']
   action :create
 end"""

# Percorso della cartella
cartella = '../glitch-datasets/chef/oracle-dataset'

# Funzione per calcolare la somiglianza
def calcola_somiglianza_seq(testo1, testo2):
    differ = difflib.SequenceMatcher(None, testo1, testo2)
    return differ.ratio()

def calcola_somiglianza(testo1, testo2):
    return fuzz.partial_ratio(testo1, testo2)

soglia = 35
print("=========")
# Loop attraverso i file nella cartella
for root, dirs, files in os.walk(cartella):
    for nome_file in files:
        percorso_file = os.path.join(root, nome_file)
        with open(percorso_file, 'r', encoding='utf-8', errors='ignore') as f:
            contenuto = f.read().lower().strip()
            somiglianza = fuzz.token_sort_ratio(testo_script, contenuto)
            if somiglianza >= soglia:
                print(f'Somiglianza con {nome_file}: {somiglianza}%')