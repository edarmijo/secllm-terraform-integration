from configurator import *

#
# Smell Analyzer
#
class SmellAnalyzer:

    # We need the configurator 
    def __init__(self, configurator):
        self.configurator = configurator

    #
    # Analyze the 'script' to detect the smell 'name' using 'prompt'
    #
    def analyze(self, script_type, name, prompt, script, tokens):
        """Checks if a specific smell exists in the given script."""
        # Find the smell configuration based on the name
        smell = self.configurator.getSmellConfig(name)
        
        if not smell:
            raise ValueError(f"Smell with name '{name}' not found in configuration.")
        
        # Now we have the smell details

        severity = smell['severity']
        description = smell['description']

        specificModel = smell['model']
        answerKey = smell['answerKey']
        analysisStart = smell['analysisStart']
        analysisEnd = smell['analysisEnd']
        temperature = smell['temperature']
        backoff_factor = smell.get('backoff_factor',1.0)
        return_confidence = smell.get('return_confidence', True)
        use_cache = smell.get('cache', False)

        #cache = smell['cache']

        if isinstance(specificModel, dict):
            if script_type.lower() in specificModel:
                specificModel = specificModel.get(script_type.lower())
            else:
                mdef = specificModel["default"]
                if mdef == "$":
                    specificModel = self.configurator.model
                else:
                    specificModel = mdef

        #print(prompt.format(script=script))
        #print(f"temperature {temperature} {specificModel}")


        cleaned_text, confidence = self.configurator.llm_call(self.configurator.system_prompt, 
                                                            prompt.replace('{script}', script),
                                                            specificModel,
                                                            tokens,
                                                            temperature,
                                                            backoff_factor,
                                                            use_cache)

        #print(cleaned_text)
        i = cleaned_text.find(analysisStart)
        analysis = ''

        if i != -1:
            j = cleaned_text.find(analysisEnd)
            s = len(analysisStart)
            analysis = cleaned_text[i+s:j]

        i = cleaned_text.find(answerKey)
        if i !=-1:
            if len(analysis) == 0:
                analysis = cleaned_text[0:i]
            cleaned_text = cleaned_text[i+8:].strip()

            #print("FOUND ANSWER", cleaned_text)
        else:    
            cleaned_text = ""
        res = []
        if len(cleaned_text)>0:
            if cleaned_text.lower().find("none") !=-1:
                # return None
                ss = {"smell":name, "lines":[], "description":description, "severity":severity, "analysis":"None", "confidence":confidence}
                return ss
            res = cleaned_text.split(", ")
                        
            if len(res) == 1 and cleaned_text.find(",") !=-1:
                res = cleaned_text.split(",")
                
            try:
                res = list(set(cleaned_text.split(",")))
                res.sort(key=lambda x: int(x.strip()))
            except Exception:
                pass
            for elem in res:
                try:
                    int(elem)
                except ValueError:
                    ss = {"smell":name, "lines":[], "description":description, "severity":severity, "analysis":"None", "confidence":confidence}
                    return ss
                    #return None
            ss = {"smell":name, "lines":res, "description":description, "severity":severity, "analysis":analysis, "confidence":confidence}
            return ss
        else:
            ss = {"smell":name, "lines":[], "description":description, "severity":severity, "analysis":"None", "confidence":confidence}
            return ss

