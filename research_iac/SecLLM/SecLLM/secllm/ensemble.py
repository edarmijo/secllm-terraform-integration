import concurrent.futures
from typing import Callable, List, Dict, Any, Optional
from collections import Counter, defaultdict
import threading
import traceback

class EnsembleManager:
    """
    A class to manage ensemble execution with majority voting on results.
    
    The ensemble can run in parallel or sequential mode and applies majority voting
    based on line numbers to determine the most likely result.
    """
    
    def __init__(self, 
                 func: Callable,
                 n_instances: int = 5,
                 parallel: bool = True,
                 max_workers: Optional[int] = None):
        """
        Initialize the EnsembleManager.
        
        Args:
            func: The function to execute for each ensemble instance.
                  Should return None or a dictionary with keys:
                  'smell', 'lines', 'description', 'severity', 'analysis', 'confidence'
            n_instances: Number of instances in the ensemble (default: 5)
            parallel: Whether to run instances in parallel (default: True)
            max_workers: Maximum number of parallel workers (default: None, uses default ThreadPoolExecutor behavior)
        """
        self.func = func
        print(f"EnsembleManager initialized with func: {func}")
        self.n_instances = n_instances
        self.parallel = parallel
        self.max_workers = max_workers
        self._lock = threading.Lock()
    
    def _parse_lines(self, lines: Any) -> set:
        """
        Parse lines field into a set of line numbers.
        
        Args:
            lines: Can be a list, set, string (comma/newline separated), or single value
            
        Returns:
            Set of line numbers as integers
        """
        line_set = set()
        
        if lines is None:
            return line_set
        
        # If it's already a list or set
        if isinstance(lines, (list, set, tuple)):
            for line in lines:
                try:
                    line_set.add(int(str(line).strip()))
                except (ValueError, AttributeError):
                    continue
        # If it's a string
        elif isinstance(lines, str):
            # Split by comma or newline
            parts = lines.replace(',', '\n').split('\n')
            for part in parts:
                try:
                    line_num = int(part.strip())
                    line_set.add(line_num)
                except (ValueError, AttributeError):
                    continue
        # Single value
        else:
            try:
                line_set.add(int(lines))
            except (ValueError, TypeError):
                pass
        
        return line_set
    
    def _create_line_signature(self, lines_set: set) -> tuple:
        """
        Create a hashable signature from a set of lines.
        
        Args:
            lines_set: Set of line numbers
            
        Returns:
            Sorted tuple of line numbers
        """
        return tuple(sorted(lines_set))
    
    def _get_confidence(self, result: Dict[str, Any]) -> float:
        """
        Extract and convert confidence value from result.
        
        Args:
            result: Result dictionary
            
        Returns:
            Confidence value as float, or 0.0 if not available or invalid
        """
        try:
            confidence = result.get('confidence')
            if confidence is None:
                return 0.0
            return float(confidence)
        except (ValueError, TypeError):
            return 0.0
    
    def _execute_instance(self, instance_id: int, *args, **kwargs) -> Optional[Dict[str, Any]]:
        """
        Execute a single instance of the ensemble.
        
        Args:
            instance_id: The ID of the instance
            *args: Positional arguments to pass to the function
            **kwargs: Keyword arguments to pass to the function
            
        Returns:
            Result dictionary or None
        """
        try:
            print(f"[Instance {instance_id}] Starting execution...")
            result = self.func(*args, **kwargs)
            print(f"[Instance {instance_id}] Execution completed. Result is None: {result is None}")
            
            # Validate result format
            if result is not None:
                if not isinstance(result, dict):
                    print(f"Warning: Instance {instance_id} returned non-dict result: {type(result)}")
                    return None
                
                required_keys = {'smell', 'lines', 'description', 'severity', 'analysis', 'confidence'}
                missing_keys = required_keys - set(result.keys())
                if missing_keys:
                    print(f"Warning: Instance {instance_id} returned incomplete dictionary. Missing keys: {missing_keys}")
                    return None
            
            return result
        except Exception as e:
            print(f"Error in instance {instance_id}: {str(e)}")
            traceback.print_exc()
            return None
    
    def _majority_voting(self, results: List[Optional[Dict[str, Any]]]) -> Optional[Dict[str, Any]]:
        """
        Apply majority voting to select the most common result based on line numbers.
        In case of tie, select the one with highest confidence, or the first one if confidence is not available.
        
        Args:
            results: List of result dictionaries from all instances
            
        Returns:
            The result with the most common line signature, or None if all results are None
        """
        # Filter out None results
        valid_results = [r for r in results if r is not None]
        
        if not valid_results:
            return None
        
        # Group results by their line signatures
        signature_to_results = defaultdict(list)
        
        for result in valid_results:
            lines_set = self._parse_lines(result['lines'])
            signature = self._create_line_signature(lines_set)
            signature_to_results[signature].append(result)
        
        # Count votes for each signature
        signature_counts = Counter()
        for signature, result_list in signature_to_results.items():
            signature_counts[signature] = len(result_list)
        
        # Find the maximum vote count
        max_votes = max(signature_counts.values())
        
        # Get all signatures with the maximum vote count (handles ties)
        tied_signatures = [sig for sig, count in signature_counts.items() if count == max_votes]
        
        # If there's only one winner, return it
        if len(tied_signatures) == 1:
            winning_signature = tied_signatures[0]
            winning_results = signature_to_results[winning_signature]
            winner = winning_results[0]
            
            # Optionally, aggregate confidence from all matching results
            if len(winning_results) > 1:
                avg_confidence = sum(
                    self._get_confidence(r) for r in winning_results
                ) / len(winning_results)
                winner = winner.copy()
                winner['confidence'] = avg_confidence
                winner['ensemble_count'] = len(winning_results)
                winner['total_instances'] = len(results)
            
            return winner
        
        # Handle tie: select based on confidence
        best_signature = None
        best_confidence = -1.0
        best_result = None
        has_any_confidence = False
        
        for signature in tied_signatures:
            results_for_signature = signature_to_results[signature]
            
            # Calculate average confidence for this signature
            confidences = [self._get_confidence(r) for r in results_for_signature]
            avg_confidence = sum(confidences) / len(confidences) if confidences else 0.0
            
            # Check if any result has a non-zero confidence
            if avg_confidence > 0:
                has_any_confidence = True
            
            # Keep track of the best signature
            if avg_confidence > best_confidence:
                best_confidence = avg_confidence
                best_signature = signature
                # Select the result with the highest individual confidence from this group
                best_result = max(results_for_signature, key=lambda r: self._get_confidence(r))
        
        # If no confidence values are available, take the first signature in the tie
        if not has_any_confidence or best_signature is None:
            best_signature = tied_signatures[0]
            best_result = signature_to_results[best_signature][0]
        
        # Add ensemble metadata
        winning_results = signature_to_results[best_signature]
        if best_result:
            winner = best_result.copy()
            winner['ensemble_count'] = len(winning_results)
            winner['total_instances'] = len(results)
            
            # Update confidence to average if multiple results exist
            if len(winning_results) > 1:
                avg_confidence = sum(
                    self._get_confidence(r) for r in winning_results
                ) / len(winning_results)
                winner['confidence'] = avg_confidence
        else:
            winner = best_result
        
        return winner
    
    def run(self, *args, **kwargs) -> Dict[str, Any]:
        """
        Run the ensemble and return detailed information about all results.
        
        Args:
            *args: Positional arguments to pass to each instance function
            **kwargs: Keyword arguments to pass to each instance function
            
        Returns:
            Dictionary containing the final result and detailed voting information
        """
        results = []
        
        if self.parallel:
            print("===========> PARALLEL EXECUTION")
            # SOLUZIONE: Crea sempre un nuovo executor interno
            # con abbastanza worker per eseguire tutte le istanze
            wk = self.max_workers if (self.max_workers and self.max_workers >0) else self.n_instances

            print("WK ", wk, self.n_instances)
            with concurrent.futures.ThreadPoolExecutor(
                max_workers= wk
            ) as executor:
                print(f"========> SUBMITTING {self.n_instances} tasks")
                futures = [
                    executor.submit(self._execute_instance, i, *args, **kwargs)
                    for i in range(self.n_instances)
                ]
                print(f"========> SUBMITTED {len(futures)} futures")
                
                for i, future in enumerate(concurrent.futures.as_completed(futures)):
                    try:
                        print(f"========> Waiting for result {i+1}/{len(futures)}")
                        result = future.result(timeout=300)  # 5 minute timeout
                        print(f"========> GOT RESULT {i+1}, is None: {result is None}")
                        results.append(result)
                    except concurrent.futures.TimeoutError:
                        print(f"Error: Future {i} timed out after 300 seconds")
                        traceback.print_exc()
                        results.append(None)
                    except Exception as e:
                        print(f"Error retrieving result {i}: {str(e)}")
                        traceback.print_exc()
                        results.append(None)
        else:
            print("===========> SEQUENTIAL EXECUTION")
            # Run instances sequentially
            for i in range(self.n_instances):
                result = self._execute_instance(i, *args, **kwargs)
                results.append(result)
        
        print(f"========> All instances completed. Total results: {len(results)}")
        
        # Count signatures for voting details
        signature_counts = Counter()
        signature_confidences = defaultdict(list)
        valid_results = [r for r in results if r is not None]
        
        for result in valid_results:
            lines_set = self._parse_lines(result['lines'])
            signature = self._create_line_signature(lines_set)
            signature_counts[signature] += 1
            signature_confidences[signature].append(self._get_confidence(result))
        
        # Calculate average confidence for each signature
        signature_avg_confidence = {
            sig: sum(confs) / len(confs) if confs else 0.0
            for sig, confs in signature_confidences.items()
        }
        
        # Apply majority voting
        final_result = self._majority_voting(results)
        
        return final_result

        #return {
        #    'final_result': final_result,
        #    'all_results': results,
        #    'valid_count': len(valid_results),
        #    'none_count': len(results) - len(valid_results),
        #    'signature_votes': dict(signature_counts),
        #    'signature_avg_confidence': signature_avg_confidence,
        #    'total_instances': len(results)
        #}


# Example usage
if __name__ == "__main__":
    import random
    
    # Example function that returns results with different line numbers
    def example_detection_func(code: str) -> Optional[Dict[str, Any]]:
        """Example function that simulates smell detection"""
        
        # Simulate some randomness
        if random.random() < 0.1:  # 10% chance of returning None
            return None
        
        # Simulate different possible line detections
        possible_lines = [
            [1, 10, 23],
            [1, 23, 44],
            [1, 10, 23, 44],
            [1, 23, 33],
            [1, 10, 33]
        ]
        
        chosen_lines = random.choice(possible_lines)
        
        return {
            "smell": "LongMethod",
            "lines": chosen_lines,
            "description": "Method is too long",
            "severity": "high",
            "analysis": "This method contains too many lines of code",
            "confidence": random.uniform(0.7, 0.95)
        }
    
    # Test with tie scenario
    def test_tie_scenario(code: str) -> Optional[Dict[str, Any]]:
        """Test function that simulates a tie scenario"""
        
        # Force a tie with different confidences
        scenarios = [
            {"lines": [1, 10, 23], "confidence": 0.8},  # 2 votes, avg conf 0.825
            {"lines": [1, 10, 23], "confidence": 0.85},
            {"lines": [1, 23, 44], "confidence": 0.9},  # 2 votes, avg conf 0.9 (should win)
            {"lines": [1, 23, 44], "confidence": 0.9},
            {"lines": [1, 10, 33], "confidence": 0.75}, # 1 vote
        ]
        
        # Use a counter to cycle through scenarios
        if not hasattr(test_tie_scenario, 'counter'):
            test_tie_scenario.counter = 0
        
        result_data = scenarios[test_tie_scenario.counter % len(scenarios)]
        test_tie_scenario.counter += 1
        
        return {
            "smell": "LongMethod",
            "lines": result_data["lines"],
            "description": "Method is too long",
            "severity": "high",
            "analysis": "This method contains too many lines of code",
            "confidence": result_data["confidence"]
        }
    
    # Test 1: Regular ensemble
    print("="*60)
    print("TEST 1: Regular ensemble execution")
    print("="*60)
    ensemble = EnsembleManager(
        func=example_detection_func,
        n_instances=5,
        parallel=True
    )
    
    detailed = ensemble.run(code="sample code here")
    
    print(f"\nTotal instances: {detailed['total_instances']}")
    print(f"Valid results: {detailed['valid_count']}")
    print(f"None results: {detailed['none_count']}")
    
    if detailed['final_result']:
        print("\nFinal Result:")
        print(f"  Smell: {detailed['final_result']['smell']}")
        print(f"  Lines: {detailed['final_result']['lines']}")
        print(f"  Confidence: {detailed['final_result'].get('confidence', 'N/A')}")
        if 'ensemble_count' in detailed['final_result']:
            print(f"  Votes: {detailed['final_result']['ensemble_count']}/{detailed['final_result']['total_instances']}")
    else:
        print("\nNo valid result found")
    
    # Test 2: Tie scenario with confidence-based selection
    print("\n" + "="*60)
    print("TEST 2: Tie scenario with confidence-based selection")
    print("="*60)
    ensemble_tie = EnsembleManager(
        func=test_tie_scenario,
        n_instances=5,
        parallel=False  # Sequential to maintain order
    )
    
    detailed = ensemble_tie.run(code="sample code here")
    
    print(f"\nTotal instances: {detailed['total_instances']}")
    print(f"Valid results: {detailed['valid_count']}")
    print(f"None results: {detailed['none_count']}")
    print("\nVoting distribution:")
    for signature, count in detailed['signature_votes'].items():
        avg_conf = detailed['signature_avg_confidence'].get(signature, 0.0)
        print(f"  Lines {signature}: {count} votes, avg confidence: {avg_conf:.3f}")
    
    if detailed['final_result']:
        print(f"\nWinner: Lines {detailed['final_result']['lines']}")
        print(f"Winner Confidence: {detailed['final_result'].get('confidence', 'N/A')}")
        print("(Should be [1, 23, 44] due to higher confidence in tie)")