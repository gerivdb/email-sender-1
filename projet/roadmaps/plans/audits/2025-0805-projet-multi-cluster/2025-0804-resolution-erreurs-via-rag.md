## 1. **Mécanisme de Retry avec Exponential Backoff**

La méthode la plus robuste utilisée dans ce repository est le système de retry avec backoff exponentiel, comme implémenté dans `rag_tutorials/corrective_rag/corrective_rag.py::execute_tavily_search` :

```python
@retry(stop=stop_after_attempt(3), wait=wait_exponential(multiplier=1, min=4, max=10))
def execute_tavily_search(tool, query):
return tool.invoke({"query": query})
```

**Avantages :**
- Retry automatique jusqu'à 3 tentatives
- Temps d'attente progressif (4-10 secondes)
- Évite la surcharge du service

## 2. **Système de Fallback Multi-Niveaux**

Le repository implémente des mécanismes de fallback sophistiqués, particulièrement visible dans `rag_tutorials/hybrid_search_rag/main.py::handle_fallback` :

```python
def handle_fallback(query: str) -> str:
try:
# Tentative principale avec Anthropic
client = anthropic.Anthropic(api_key=st.session_state.user_env["ANTHROPIC_API_KEY"])
# ... logique principale
return message.content[0].text
except Exception as e:
logger.error(f"Fallback error: {str(e)}")
st.error(f"Fallback error: {str(e)}")
return "I apologize, but I encountered an error..."
```

## 3. **Architecture Corrective RAG**

Le système `rag_tutorials/corrective_rag/corrective_rag.py::workflow` implémente une approche corrective multi-étapes :

- **Évaluation de pertinence** : Vérifie la qualité des documents récupérés
- **Transformation de requête** : Reformule les questions mal comprises
- **Recherche web de secours** : Utilise Tavily API si les documents locaux sont insuffisants
- **Génération finale** : Produit une réponse consolidée

## 4. **Gestion d'Erreurs Granulaire**

Les fonctions implémentent des blocs try-catch spécialisés avec :
- **Logging détaillé** des erreurs
- **Messages utilisateur informatifs**
- **Continuité de service** même en cas d'échec partiel

## 5. **Validation et Nettoyage des Données**

Le système effectue une validation en amont :
- Vérification des clés API
- Validation des formats de documents
- Nettoyage des réponses JSON malformées

## 6. **Feedback Loop et Apprentissage**

Le repository utilise `rag_tutorials/agentic_rag_math_agent/logs/feedback_log.json` pour :
- Enregistrer les erreurs utilisateur
- Analyser les patterns d'échec
- Améliorer les performances futures

## **Recommandations pour Corriger des Erreurs Nombreuses :**

1. **Implémentez des retry avec backoff exponentiel** pour les appels API
2. **Créez des systèmes de fallback** à plusieurs niveaux
3. **Loggez systématiquement** les erreurs avec contexte
4. **Validez les entrées** avant traitement
5. **Utilisez des timeouts appropriés** pour éviter les blocages
6. **Implémentez des circuit breakers** pour les services défaillants
7. **Créez des mécanismes de feedback** pour l'apprentissage continu


# Améliorations pour le Document : Méthodes de Correction d'Erreurs dans les Applications LLM

Voici les améliorations suggérées sous forme d'addendum pour enrichir votre documentation existante sur les méthodes de correction d'erreurs dans les repositories d'applications LLM.

## **Addendum 1 : Stratégies Avancées de Retry et Backoff**

### **Patterns de Retry Sophistiqués**

#### **Retry Conditionnel avec Classification d'Erreurs**
```python
from tenacity import retry, stop_after_attempt, wait_exponential, retry_if_exception_type
from openai import RateLimitError, APITimeoutError, InternalServerError

@retry(
    retry=retry_if_exception_type((RateLimitError, APITimeoutError, InternalServerError)),
    stop=stop_after_attempt(5),
    wait=wait_exponential(multiplier=1, min=2, max=30),
    reraise=True
)
def call_llm_with_smart_retry(prompt, model="gpt-4"):
    """Retry intelligent basé sur le type d'erreur"""
    return client.completions.create(
        model=model,
        prompt=prompt,
        max_tokens=150
    )
```

#### **Jitter Aléatoire pour Éviter le "Thundering Herd"**
```python
import random
from tenacity import wait_random_exponential

@retry(
    wait=wait_random_exponential(multiplier=1, min=1, max=60),
    stop=stop_after_attempt(6)
)
def resilient_api_call(data):
    """Évite la congestion avec du jitter aléatoire"""
    # Le jitter empêche tous les clients de retry simultanément
    return external_api.call(data)
```

### **Métriques Avancées de Monitoring des Retries**
```python
import time
from collections import defaultdict

class RetryMetrics:
    def __init__(self):
        self.attempt_counts = defaultdict(int)
        self.success_rates = {}
        self.backoff_times = []
    
    def record_attempt(self, operation, attempt_num, success=False):
        self.attempt_counts[f"{operation}_attempt_{attempt_num}"] += 1
        if success:
            self.success_rates[operation] = self.success_rates.get(operation, 0) + 1
    
    def get_retry_analytics(self):
        """Analyse des patterns de retry pour optimisation"""
        return {
            "total_retries": sum(self.attempt_counts.values()),
            "operations_requiring_retries": len([k for k in self.attempt_counts.keys() if "attempt_2" in k]),
            "average_success_rate": sum(self.success_rates.values()) / len(self.success_rates) if self.success_rates else 0
        }
```

## **Addendum 2 : Circuit Breaker Patterns Avancés**

### **Circuit Breaker Adaptatif avec Machine Learning**
```python
import numpy as np
from datetime import datetime, timedelta

class AdaptiveCircuitBreaker:
    def __init__(self, failure_threshold=5, recovery_timeout=60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = "CLOSED"  # CLOSED, OPEN, HALF_OPEN
        self.response_times = []
        self.success_rate_history = []
    
    def call(self, func, *args, **kwargs):
        if self.state == "OPEN":
            if self._should_attempt_reset():
                self.state = "HALF_OPEN"
            else:
                raise CircuitBreakerOpenError("Circuit breaker is OPEN")
        
        try:
            start_time = time.time()
            result = func(*args, **kwargs)
            response_time = time.time() - start_time
            
            self._record_success(response_time)
            return result
            
        except Exception as e:
            self._record_failure()
            raise
    
    def _record_success(self, response_time):
        self.response_times.append(response_time)
        if self.state == "HALF_OPEN":
            self.state = "CLOSED"
            self.failure_count = 0
    
    def _record_failure(self):
        self.failure_count += 1
        self.last_failure_time = datetime.now()
        if self.failure_count >= self.failure_threshold:
            self.state = "OPEN"
    
    def _should_attempt_reset(self):
        return (datetime.now() - self.last_failure_time).seconds > self.recovery_timeout
```

### **Circuit Breaker avec Monitoring en Temps Réel**
```python
class MonitoredCircuitBreaker:
    def __init__(self, name, threshold=5):
        self.name = name
        self.threshold = threshold
        self.metrics = {
            "total_calls": 0,
            "failed_calls": 0,
            "state_changes": [],
            "avg_response_time": 0
        }
    
    def get_health_status(self):
        """Retourne l'état de santé du circuit breaker"""
        failure_rate = self.metrics["failed_calls"] / max(self.metrics["total_calls"], 1)
        return {
            "name": self.name,
            "state": self.state,
            "failure_rate": failure_rate,
            "health_score": max(0, 100 - (failure_rate * 100)),
            "recent_state_changes": self.metrics["state_changes"][-5:]
        }
```

## **Addendum 3 : Validation et Sanitisation Avancées**

### **Validation Sémantique avec LLM-as-a-Judge**
```python
from pydantic import BaseModel, validator
import instructor

class SemanticValidator:
    def __init__(self, client):
        self.client = client
    
    @instructor.llm_validator("La réponse doit être factuelle, sans hallucination, et appropriée au contexte professionnel")
    def validate_llm_output(self, value: str) -> str:
        """Validation sémantique utilisant un LLM juge"""
        return value

class ValidatedResponse(BaseModel):
    content: str
    confidence_score: float
    safety_flags: List[str] = []
    
    @validator('content')
    def validate_content_safety(cls, v):
        # Vérifications de sécurité automatisées
        safety_checks = [
            check_for_pii(v),
            check_for_harmful_content(v),
            check_for_prompt_injection(v)
        ]
        if any(safety_checks):
            raise ValueError("Contenu non sécurisé détecté")
        return v
```

### **Sanitisation Intelligente des Prompts**
```python
import re
from typing import List, Dict

class AdvancedPromptSanitizer:
    def __init__(self):
        self.pii_patterns = {
            'email': r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b',
            'phone': r'\b\d{3}[-.]?\d{3}[-.]?\d{4}\b',
            'ssn': r'\b\d{3}-\d{2}-\d{4}\b',
            'credit_card': r'\b\d{4}[-\s]?\d{4}[-\s]?\d{4}[-\s]?\d{4}\b'
        }
        self.injection_patterns = [
            r'ignore\s+previous\s+instructions',
            r'forget\s+everything',
            r'act\s+as\s+if',
            r'pretend\s+you\s+are'
        ]
    
    def sanitize_prompt(self, prompt: str) -> Dict[str, any]:
        """Sanitise et analyse un prompt pour détecter les vulnérabilités"""
        sanitized_prompt = prompt
        detected_issues = []
        
        # Détection et masquage du PII
        for pii_type, pattern in self.pii_patterns.items():
            matches = re.findall(pattern, prompt, re.IGNORECASE)
            if matches:
                detected_issues.append(f"PII détecté: {pii_type}")
                sanitized_prompt = re.sub(pattern, f"[{pii_type.upper()}_MASKED]", sanitized_prompt, flags=re.IGNORECASE)
        
        # Détection d'injection de prompt
        for pattern in self.injection_patterns:
            if re.search(pattern, prompt, re.IGNORECASE):
                detected_issues.append("Tentative d'injection de prompt détectée")
                # Encoder ou rejeter le prompt
                sanitized_prompt = self._encode_suspicious_content(sanitized_prompt, pattern)
        
        return {
            "original_prompt": prompt,
            "sanitized_prompt": sanitized_prompt,
            "security_issues": detected_issues,
            "safety_score": self._calculate_safety_score(detected_issues)
        }
    
    def _calculate_safety_score(self, issues: List[str]) -> float:
        """Calcule un score de sécurité basé sur les problèmes détectés"""
        base_score = 100.0
        penalty_per_issue = 25.0
        return max(0.0, base_score - (len(issues) * penalty_per_issue))
```

## **Addendum 4 : Observabilité et Monitoring en Temps Réel**

### **Système de Traces Distribués pour LLM**
```python
import opentelemetry
from opentelemetry.trace import get_tracer
from contextlib import contextmanager

class LLMTracer:
    def __init__(self, service_name="llm-application"):
        self.tracer = get_tracer(service_name)
    
    @contextmanager
    def trace_llm_call(self, operation_name, **attributes):
        """Context manager pour tracer les appels LLM"""
        with self.tracer.start_as_current_span(operation_name) as span:
            # Ajout d'attributs métier
            for key, value in attributes.items():
                span.set_attribute(f"llm.{key}", value)
            
            start_time = time.time()
            try:
                yield span
                span.set_attribute("llm.success", True)
            except Exception as e:
                span.set_attribute("llm.error", str(e))
                span.set_attribute("llm.success", False)
                raise
            finally:
                duration = time.time() - start_time
                span.set_attribute("llm.duration_ms", duration * 1000)

# Utilisation
tracer = LLMTracer()

def generate_response(prompt, model="gpt-4"):
    with tracer.trace_llm_call(
        "llm_generation",
        model=model,
        prompt_length=len(prompt),
        temperature=0.7
    ) as span:
        response = client.completions.create(
            model=model,
            prompt=prompt,
            max_tokens=150
        )
        span.set_attribute("llm.tokens_used", response.usage.total_tokens)
        span.set_attribute("llm.response_length", len(response.choices[0].text))
        return response
```

### **Monitoring Real-time avec Alertes Intelligentes**
```python
from collections import deque
import asyncio

class RealTimeLLMMonitor:
    def __init__(self, window_size=100):
        self.window_size = window_size
        self.metrics = {
            'response_times': deque(maxlen=window_size),
            'error_rates': deque(maxlen=window_size),
            'token_usage': deque(maxlen=window_size),
            'quality_scores': deque(maxlen=window_size)
        }
        self.alert_thresholds = {
            'avg_response_time': 5.0,  # secondes
            'error_rate': 0.05,        # 5%
            'token_efficiency': 0.7    # ratio tokens utiles/total
        }
    
    async def record_llm_interaction(self, interaction_data):
        """Enregistre une interaction LLM et déclenche des alertes si nécessaire"""
        self.metrics['response_times'].append(interaction_data['response_time'])
        self.metrics['error_rates'].append(1 if interaction_data['error'] else 0)
        self.metrics['token_usage'].append(interaction_data['tokens_used'])
        self.metrics['quality_scores'].append(interaction_data['quality_score'])
        
        # Vérification des seuils d'alerte
        await self._check_alert_conditions()
    
    async def _check_alert_conditions(self):
        """Vérifie les conditions d'alerte et déclenche si nécessaire"""
        if len(self.metrics['response_times'])  self.alert_thresholds['avg_response_time']:
            alerts.append({
                'type': 'PERFORMANCE_DEGRADATION',
                'message': f"Temps de réponse moyen élevé: {avg_response_time:.2f}s",
                'severity': 'WARNING'
            })
        
        if current_error_rate > self.alert_thresholds['error_rate']:
            alerts.append({
                'type': 'HIGH_ERROR_RATE',
                'message': f"Taux d'erreur élevé: {current_error_rate:.2%}",
                'severity': 'CRITICAL'
            })
        
        for alert in alerts:
            await self._send_alert(alert)
    
    async def _send_alert(self, alert):
        """Envoie une alerte via les canaux configurés"""
        print(f"🚨 ALERTE [{alert['severity']}]: {alert['message']}")
        # Ici, intégrer avec Slack, email, webhooks, etc.
```

## **Addendum 5 : Patterns de Graceful Degradation**

### **Système de Fallback Multi-Niveaux Intelligent**
```python
from abc import ABC, abstractmethod
from enum import Enum

class FallbackStrategy(Enum):
    ALTERNATIVE_MODEL = "alternative_model"
    CACHED_RESPONSE = "cached_response"
    SIMPLIFIED_RESPONSE = "simplified_response"
    HUMAN_HANDOFF = "human_handoff"

class ResponseQuality(Enum):
    FULL = "full"
    DEGRADED = "degraded"
    MINIMAL = "minimal"
    FALLBACK = "fallback"

class IntelligentFallbackManager:
    def __init__(self):
        self.fallback_chain = [
            (self._try_alternative_model, FallbackStrategy.ALTERNATIVE_MODEL),
            (self._try_cached_response, FallbackStrategy.CACHED_RESPONSE),
            (self._try_simplified_response, FallbackStrategy.SIMPLIFIED_RESPONSE),
            (self._human_handoff, FallbackStrategy.HUMAN_HANDOFF)
        ]
        self.quality_degradation_map = {
            FallbackStrategy.ALTERNATIVE_MODEL: ResponseQuality.FULL,
            FallbackStrategy.CACHED_RESPONSE: ResponseQuality.DEGRADED,
            FallbackStrategy.SIMPLIFIED_RESPONSE: ResponseQuality.MINIMAL,
            FallbackStrategy.HUMAN_HANDOFF: ResponseQuality.FALLBACK
        }
    
    async def generate_with_fallback(self, prompt, context=None):
        """Génère une réponse avec fallback intelligent"""
        primary_error = None
        
        # Tentative principale
        try:
            response = await self._primary_generation(prompt, context)
            return {
                'content': response,
                'quality': ResponseQuality.FULL,
                'strategy_used': 'primary',
                'degradation_reason': None
            }
        except Exception as e:
            primary_error = e
        
        # Parcours de la chaîne de fallback
        for fallback_func, strategy in self.fallback_chain:
            try:
                response = await fallback_func(prompt, context, primary_error)
                if response:
                    return {
                        'content': response,
                        'quality': self.quality_degradation_map[strategy],
                        'strategy_used': strategy.value,
                        'degradation_reason': str(primary_error)
                    }
            except Exception as fallback_error:
                continue  # Essayer le fallback suivant
        
        # Aucun fallback n'a fonctionné
        return {
            'content': "Service temporairement indisponible. Veuillez réessayer plus tard.",
            'quality': ResponseQuality.FALLBACK,
            'strategy_used': 'error_message',
            'degradation_reason': f"Tous les fallbacks ont échoué. Erreur principale: {primary_error}"
        }
    
    async def _try_alternative_model(self, prompt, context, error):
        """Essaie un modèle alternatif (ex: GPT-3.5 si GPT-4 échoue)"""
        return await alternative_model_client.generate(prompt)
    
    async def _try_cached_response(self, prompt, context, error):
        """Recherche une réponse similaire en cache"""
        return cache_manager.find_similar_response(prompt)
    
    async def _try_simplified_response(self, prompt, context, error):
        """Génère une réponse simplifiée avec un prompt réduit"""
        simplified_prompt = self._simplify_prompt(prompt)
        return await lightweight_model.generate(simplified_prompt)
    
    async def _human_handoff(self, prompt, context, error):
        """Transfère vers un opérateur humain"""
        ticket_id = await create_support_ticket(prompt, error)
        return f"Votre demande a été transférée à notre équipe support (Ticket #{ticket_id})"
```

## **Addendum 6 : Exemple d'Implémentation Complète**

### **Classe LLMManager Robuste**
```python
class RobustLLMManager:
    def __init__(self):
        self.retry_manager = RetryManager()
        self.circuit_breaker = AdaptiveCircuitBreaker()
        self.validator = SemanticValidator()
        self.monitor = RealTimeLLMMonitor()
        self.fallback_manager = IntelligentFallbackManager()
        self.sanitizer = AdvancedPromptSanitizer()
    
    async def safe_generate(self, prompt: str, **kwargs) -> Dict:
        """Point d'entrée principal pour la génération sécurisée"""
        
        # 1. Sanitisation du prompt
        sanitization_result = self.sanitizer.sanitize_prompt(prompt)
        if sanitization_result['safety_score'] < 50:
            return {
                'success': False,
                'error': 'Prompt rejeté pour des raisons de sécurité',
                'details': sanitization_result['security_issues']
            }
        
        # 2. Génération avec fallback
        try:
            result = await self.fallback_manager.generate_with_fallback(
                sanitization_result['sanitized_prompt'], 
                kwargs
            )
            
            # 3. Validation de la réponse
            if result['quality'] in [ResponseQuality.FULL, ResponseQuality.DEGRADED]:
                validation_result = self.validator.validate_response(result['content'])
                if not validation_result['is_valid']:
                    # Re-générer ou utiliser un fallback
                    result = await self._handle_validation_failure(prompt, validation_result)
            
            # 4. Monitoring et métriques
            await self.monitor.record_llm_interaction({
                'prompt': prompt,
                'response': result['content'],
                'quality': result['quality'].value,
                'strategy_used': result['strategy_used'],
                'success': True
            })
            
            return {
                'success': True,
                'content': result['content'],
                'metadata': {
                    'quality': result['quality'].value,
                    'strategy_used': result['strategy_used'],
                    'safety_score': sanitization_result['safety_score']
                }
            }
            
        except Exception as e:
            await self.monitor.record_llm_interaction({
                'prompt': prompt,
                'error': str(e),
                'success': False
            })
            return {
                'success': False,
                'error': f'Erreur lors de la génération: {str(e)}',
                'fallback_content': "Service temporairement indisponible"
            }
```

Ces améliorations fournissent des patterns concrets et actionnables que vos agents IA peuvent utiliser pour construire des applications LLM plus robustes. Chaque section peut être intégrée individuellement selon vos besoins spécifiques, et les exemples de code sont directement utilisables dans vos projets.

[1] https://bdtechtalks.com/2024/09/20/llm-application-error-analysis/
[2] https://keestalkstech.com/python-utility-function-retry-with-exponential-backoff/
[3] https://www.geeksforgeeks.org/what-is-circuit-breaker-pattern-in-microservices/
[4] https://arxiv.org/html/2410.06949v2
[5] https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/retry-backoff.html
[6] https://www.baeldung.com/cs/microservices-circuit-breaker-pattern
[7] https://rubyllm.com/guides/error-handling
[8] https://www.pullrequest.com/blog/retrying-and-exponential-backoff-smart-strategies-for-robust-software/
[9] https://docs.aws.amazon.com/prescriptive-guidance/latest/cloud-design-patterns/circuit-breaker.html
[10] https://zuplo.com/blog/2025/02/11/best-practices-for-api-error-handling
[11] https://learn.microsoft.com/en-us/azure/storage/blobs/storage-retry-policy-python
[12] https://microservices.io/patterns/reliability/circuit-breaker.html
[13] https://python.langchain.com/docs/how_to/tools_error/
[14] https://python.useinstructor.com/concepts/retrying/
[15] https://blog.octo.com/circuit-breaker-un-pattern-pour-fiabiliser-vos-systemes-distribues-ou-microservices-partie-2
[16] https://www.vellum.ai/blog/what-to-do-when-an-llm-request-fails
[17] https://pypi.org/project/backoff/
[18] https://learn.microsoft.com/en-us/azure/architecture/patterns/circuit-breaker
[19] https://apxml.com/courses/building-advanced-llm-agent-tools/chapter-1-llm-agent-tooling-foundations/tool-error-handling
[20] https://www.geeksforgeeks.org/system-design/retry-pattern-in-microservices/
[21] https://docs.cognigy.com/ai/empower/llms/fallback/
[22] https://library.fiveable.me/key-terms/introduction-cognitive-science/graceful-degradation
[23] https://convogenie.ai/blog/how-contextual-error-recovery-works-in-ai-agents
[24] https://muegenai.com/docs/data-science/building-llm-powered-applications-with-langchain-langgraph/module-6-building-with-langgraph/implementing-branching-logic-and-fallback-handling/
[25] https://dataforest.ai/glossary/graceful-degradation
[26] https://openreview.net/forum?id=IPZ28ZqD4I
[27] https://pretalx.com/pyconde-pydata-2024/talk/QCNXLW/
[28] https://blog.logrocket.com/guide-graceful-degradation-web-development/
[29] https://arxiv.org/html/2408.01055v1
[30] https://dev.to/simplr_sh/stop-worrying-about-llm-downtime-build-resilient-ai-apps-with-ai-fallback-1bkc
[31] https://dev.to/teclearn/web-theory-part-8-graceful-degradation-soft-failure-and-fault-tolerance-explained-7n0
[32] https://arxiv.org/html/2407.06071v2
[33] https://newrelic.com/fr/blog/best-practices/design-software-for-graceful-degradation
[34] https://labelstud.io/blog/llm-evaluation-comparing-four-methods-to-automatically-detect-errors/
[35] https://www.youtube.com/watch?v=3A9fDBrklP4
[36] https://prism.sustainability-directory.com/area/ai-graceful-degradation/
[37] https://apxml.com/courses/langchain-production-llm/chapter-2-sophisticated-agents-tools/agent-error-handling
[38] https://portkey.ai/blog/how-to-design-a-reliable-fallback-system-for-llm-apps-using-an-ai-gateway
[39] https://www.sciencedirect.com/topics/computer-science/graceful-degradation
[40] https://www.gigaspaces.com/data-terms/llm-validation
[41] https://boxplot.com/prompt-sanitization/
[42] https://www.lasso.security/blog/prompt-injection
[43] https://python.useinstructor.com/concepts/semantic_validation/
[44] https://docs.aws.amazon.com/wellarchitected/latest/generative-ai-lens/gensec04-bp02.html
[45] https://www.helicone.ai/blog/preventing-prompt-injection
[46] https://www.managementsolutions.com/sites/default/files/minisite/static/72b0015f-39c9-4a52-ba63-872c115bfbd0/llm/pdf/rise-of-llm-05.pdf
[47] https://www.symbioticsec.ai/blog/validating-inputs-input-sanitization-step-by-step-guide
[48] https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html
[49] https://www.confident-ai.com/blog/llm-evaluation-metrics-everything-you-need-for-llm-evaluation
[50] https://www.enkryptai.com/glossary/input-sanitization
[51] https://techcommunity.microsoft.com/blog/microsoft-security-blog/architecting-secure-gen-ai-applications-preventing-indirect-prompt-injection-att/4221859
[52] https://www.mechanical-orchard.com/insights/llm-toolkit-validation-is-all-you-need
[53] https://konghq.com/blog/enterprise/building-pii-sanitization-for-llms-and-agentic-ai
[54] https://www.aquasec.com/cloud-native-academy/cloud-attacks/prompt-injection/
[55] https://www.iguazio.com/blog/llm-validation-and-evaluation/
[56] https://academy.test.io/en/articles/9582067-input-validation-for-malicious-users-in-ai-infused-application-testing
[57] https://www.reddit.com/r/googlecloud/comments/1df7lhn/what_are_current_best_practices_for_avoiding/
[58] https://eugeneyan.com/writing/llm-patterns/
[59] https://www.nightfall.ai/blog/prompt-sanitization-5-steps-for-protecting-data-privacy-in-ai-apps
[60] https://galileo.ai/blog/llm-monitoring-real-time-batch-approaches
[61] https://www.dynatrace.com/knowledge-base/ai-observability/
[62] https://logit.io/blog/post/enhancing-log-analysis-with-machine-learning/
[63] https://contentgecko.io/kb/llmo/tools-for-monitoring-llmo-performance/
[64] https://www.ibm.com/think/insights/observability-gen-ai
[65] https://arxiv.org/abs/2307.16714
[66] https://coralogix.com/guides/llm-observability-tools/
[67] https://newrelic.com/blog/how-to-relic/ai-in-observability
[68] https://www.hopsworks.ai/dictionary/machine-learning-logs
[69] https://arize.com/blog/llm-observability-for-ai-agents-and-applications/
[70] https://coralogix.com/ai-blog/the-best-ai-observability-tools-in-2025/
[71] https://blog.rmhogervorst.nl/blog/2024/11/03/logging-for-mlops/
[72] https://langfuse.com/faq/all/llm-observability
[73] https://azure.github.io/AI-in-Production-Guide/chapters/chapter_12_keeping_log_observability
[74] https://neptune.ai/blog/machine-learning-approach-to-log-analytics
[75] https://www.confident-ai.com/blog/what-is-llm-observability-the-ultimate-llm-monitoring-guide
[76] https://middleware.io/blog/how-ai-based-insights-can-change-the-observability/
[77] https://www.sciencedirect.com/science/article/pii/S0950584924000557
[78] https://www.netdata.cloud/academy/llm-observability/
[79] https://www.logicmonitor.com/ai-observability


# **Addendum Approfondis : Techniques RAG Avancées pour la Résolution d'Erreurs**

Basé sur mes recherches approfondies des techniques RAG avancées et des patterns de gestion d'erreurs dans les systèmes d'IA distribués, voici des suggestions d'améliorations concrètes et actionnables pour enrichir votre documentation.

## **Addendum 7 : Patterns de Corrective RAG Adaptatifs**

### **Système d'Évaluation Continue avec Auto-Correction**
Inspiré des recherches récentes sur le Corrective RAG[1][2], voici un pattern actionnable pour implémenter une évaluation continue :

```python
class AdaptiveCorrectionEngine:
    def __init__(self):
        self.relevance_evaluator = RelevanceEvaluator()
        self.web_search = TavilyWebSearch()
        self.query_transformer = QueryTransformer()
        self.quality_thresholds = {
            'high_relevance': 0.8,
            'medium_relevance': 0.5,
            'low_relevance': 0.2
        }
        
    async def corrective_generation(self, query: str, retrieved_docs: List[str]) -> Dict:
        """Pattern CRAG avec correction multi-niveaux"""
        try:
            # Étape 1 : Évaluation de la pertinence
            relevance_scores = await self._evaluate_relevance(query, retrieved_docs)
            avg_relevance = sum(relevance_scores) / len(relevance_scores)
            
            # Étape 2 : Décision basée sur la qualité
            if avg_relevance >= self.quality_thresholds['high_relevance']:
                return await self._direct_generation(query, retrieved_docs)
            elif avg_relevance >= self.quality_thresholds['medium_relevance']:
                return await self._hybrid_generation(query, retrieved_docs)
            else:
                return await self._corrective_generation_with_search(query)
                
        except Exception as e:
            return await self._fallback_generation(query, str(e))
    
    async def _corrective_generation_with_search(self, query: str) -> Dict:
        """Génération corrective avec recherche web"""
        # Transformation de la requête pour la recherche web
        web_query = await self.query_transformer.optimize_for_web_search(query)
        
        # Recherche web de secours
        web_results = await self.web_search.search(web_query)
        
        # Génération avec contexte augmenté
        return await self._generate_with_augmented_context(query, web_results)
    
    async def _evaluate_relevance(self, query: str, docs: List[str]) -> List[float]:
        """Évaluation LLM-as-a-Judge pour la pertinence"""
        evaluation_prompt = f"""
        Évaluez la pertinence de chaque document pour répondre à la question suivante :
        Question : {query}
        
        Pour chaque document, donnez un score de 0.0 à 1.0 où :
        - 1.0 = Parfaitement pertinent et contient l'information nécessaire
        - 0.5 = Partiellement pertinent mais incomplet
        - 0.0 = Non pertinent ou hors sujet
        
        Format de réponse : [score1, score2, score3, ...]
        """
        
        scores = await self.relevance_evaluator.evaluate_batch(
            evaluation_prompt, docs
        )
        return scores
```

### **Pattern de Knowledge Refinement Granulaire**
```python
class KnowledgeRefinementEngine:
    def __init__(self):
        self.strip_extractor = KnowledgeStripExtractor()
        self.relevance_filter = RelevanceFilter()
        
    async def refine_knowledge(self, query: str, documents: List[str]) -> List[str]:
        """Raffinement granulaire des connaissances récupérées"""
        refined_knowledge = []
        
        for doc in documents:
            # Division en strips de connaissance
            knowledge_strips = await self.strip_extractor.extract_strips(doc)
            
            # Évaluation de chaque strip
            for strip in knowledge_strips:
                relevance_score = await self._evaluate_strip_relevance(query, strip)
                
                if relevance_score > 0.6:  # Seuil de pertinence
                    refined_knowledge.append({
                        'content': strip,
                        'relevance_score': relevance_score,
                        'source_document': doc
                    })
        
        # Tri par pertinence et déduplication
        return self._deduplicate_and_sort(refined_knowledge)
```

## **Addendum 8 : Logging Structuré Intelligent pour LLM**

### **Système de Logging Multi-Niveaux avec Analyse d'Erreurs**
Basé sur les recherches sur l'analyse de logs avec LLM[3][4], voici un système de logging intelligent :

```python
import structlog
from datetime import datetime
from enum import Enum
from typing import Dict, Any, Optional

class ErrorSeverity(Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"

class IntelligentLLMLogger:
    def __init__(self):
        self.logger = structlog.get_logger()
        self.error_analyzer = LLMErrorAnalyzer()
        self.pattern_detector = ErrorPatternDetector()
        
    async def log_llm_interaction(
        self, 
        query: str, 
        response: str, 
        metadata: Dict[str, Any],
        error: Optional[Exception] = None
    ):
        """Logging structuré avec analyse intelligente"""
        
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "event_type": "llm_interaction",
            "query": query,
            "response": response,
            "metadata": {
                "model": metadata.get("model"),
                "tokens_used": metadata.get("tokens_used"),
                "latency_ms": metadata.get("latency_ms"),
                "temperature": metadata.get("temperature"),
                "context_length": len(query)
            }
        }
        
        if error:
            # Analyse intelligente de l'erreur
            error_analysis = await self._analyze_error(error, query, metadata)
            log_entry.update({
                "error_type": type(error).__name__,
                "error_message": str(error),
                "error_severity": error_analysis["severity"],
                "potential_causes": error_analysis["causes"],
                "suggested_fixes": error_analysis["fixes"],
                "error_pattern_id": error_analysis["pattern_id"]
            })
            
            # Détection de patterns récurrents
            pattern_info = await self.pattern_detector.analyze_error_pattern(error_analysis)
            if pattern_info["is_recurring"]:
                log_entry["pattern_alert"] = {
                    "occurrences": pattern_info["count"],
                    "trend": pattern_info["trend"],
                    "escalation_needed": pattern_info["escalation_needed"]
                }
        
        # Calcul de métriques de qualité
        quality_metrics = await self._calculate_quality_metrics(query, response)
        log_entry["quality_metrics"] = quality_metrics
        
        # Log avec niveau approprié
        log_level = self._determine_log_level(error, quality_metrics)
        getattr(self.logger, log_level)("LLM interaction logged", **log_entry)
        
        return log_entry
    
    async def _analyze_error(self, error: Exception, query: str, metadata: Dict) -> Dict:
        """Analyse LLM de l'erreur pour diagnostic intelligent"""
        analysis_prompt = f"""
        Analysez cette erreur LLM et fournissez un diagnostic structuré :
        
        Erreur : {type(error).__name__}: {str(error)}
        Requête : {query}
        Métadonnées : {metadata}
        
        Fournissez votre analyse au format JSON :
        {{
            "severity": "low|medium|high|critical",
            "causes": ["cause1", "cause2", ...],
            "fixes": ["fix1", "fix2", ...],
            "pattern_id": "unique_pattern_identifier",
            "is_transient": true/false,
            "recovery_strategy": "immediate|retry|escalate|fallback"
        }}
        """
        
        return await self.error_analyzer.analyze(analysis_prompt)
```

### **Pattern de Monitoring Prédictif**
```python
class PredictiveMonitoringSystem:
    def __init__(self):
        self.anomaly_detector = AnomalyDetector()
        self.performance_predictor = PerformancePredictor()
        self.alert_manager = AlertManager()
        
    async def monitor_system_health(self, metrics: Dict[str, float]):
        """Monitoring prédictif avec alertes intelligentes"""
        
        # Détection d'anomalies en temps réel
        anomalies = await self.anomaly_detector.detect_anomalies(metrics)
        
        # Prédiction de performance future
        performance_forecast = await self.performance_predictor.predict_performance(
            metrics, horizon_minutes=30
        )
        
        # Génération d'alertes proactives
        if performance_forecast["degradation_risk"] > 0.7:
            await self.alert_manager.send_proactive_alert({
                "type": "performance_degradation_predicted",
                "risk_score": performance_forecast["degradation_risk"],
                "predicted_impact": performance_forecast["impact"],
                "recommended_actions": performance_forecast["actions"],
                "time_to_impact": performance_forecast["eta_minutes"]
            })
        
        return {
            "current_health": self._calculate_health_score(metrics),
            "anomalies": anomalies,
            "forecast": performance_forecast
        }
```

## **Addendum 9 : Gestion d'État Avancée pour Agents IA**

### **Système de Persistance d'État avec Recovery**
Inspiré des recherches sur la gestion d'état des agents IA[5][6], voici un pattern robuste :

```python
import asyncio
import json
from dataclasses import dataclass, asdict
from typing import Dict, Any, Optional
from datetime import datetime

@dataclass
class AgentState:
    session_id: str
    current_task: Optional[str]
    context_history: List[Dict]
    learned_preferences: Dict[str, Any]
    error_history: List[Dict]
    performance_metrics: Dict[str, float]
    last_checkpoint: datetime
    recovery_point: Optional[str]

class StatefulAgentManager:
    def __init__(self, persistence_backend="redis"):
        self.persistence = self._init_persistence(persistence_backend)
        self.state_cache = {}
        self.checkpoint_interval = 30  # secondes
        
    async def save_agent_state(self, agent_id: str, state: AgentState):
        """Sauvegarde de l'état avec versioning"""
        try:
            # Création d'un checkpoint
            checkpoint_key = f"agent_{agent_id}_checkpoint_{datetime.utcnow().timestamp()}"
            state_data = asdict(state)
            
            # Sauvegarde atomique
            async with self.persistence.transaction() as tx:
                await tx.set(f"agent_{agent_id}_current", json.dumps(state_data))
                await tx.set(checkpoint_key, json.dumps(state_data))
                await tx.expire(checkpoint_key, 86400)  # 24h de rétention
            
            # Mise à jour du cache local
            self.state_cache[agent_id] = state
            
            return True
            
        except Exception as e:
            await self._handle_persistence_error(agent_id, e)
            return False
    
    async def recover_agent_state(self, agent_id: str) -> Optional[AgentState]:
        """Récupération d'état avec fallback intelligent"""
        try:
            # Tentative de récupération depuis l'état current
            current_state = await self.persistence.get(f"agent_{agent_id}_current")
            if current_state:
                return AgentState(**json.loads(current_state))
            
            # Fallback vers le dernier checkpoint
            checkpoints = await self.persistence.keys(f"agent_{agent_id}_checkpoint_*")
            if checkpoints:
                latest_checkpoint = max(checkpoints)
                checkpoint_data = await self.persistence.get(latest_checkpoint)
                return AgentState(**json.loads(checkpoint_data))
            
            return None
            
        except Exception as e:
            await self._handle_recovery_error(agent_id, e)
            return None
    
    async def create_recovery_point(self, agent_id: str, description: str):
        """Création de point de récupération explicite"""
        state = self.state_cache.get(agent_id)
        if state:
            state.recovery_point = description
            state.last_checkpoint = datetime.utcnow()
            await self.save_agent_state(agent_id, state)
    
    async def rollback_to_recovery_point(self, agent_id: str) -> bool:
        """Rollback vers le dernier point de récupération"""
        try:
            # Recherche du dernier point de récupération valide
            checkpoints = await self.persistence.keys(f"agent_{agent_id}_checkpoint_*")
            
            for checkpoint_key in sorted(checkpoints, reverse=True):
                checkpoint_data = await self.persistence.get(checkpoint_key)
                state_data = json.loads(checkpoint_data)
                
                if state_data.get('recovery_point'):
                    # Restauration de l'état
                    restored_state = AgentState(**state_data)
                    await self.save_agent_state(agent_id, restored_state)
                    
                    return True
            
            return False
            
        except Exception as e:
            await self._handle_rollback_error(agent_id, e)
            return False
```

### **Pattern de State Reconciliation Multi-Agent**
```python
class MultiAgentStateReconciliation:
    def __init__(self):
        self.consensus_manager = ConsensusManager()
        self.conflict_resolver = ConflictResolver()
        
    async def reconcile_distributed_state(
        self, 
        agents_states: Dict[str, AgentState]
    ) -> Dict[str, AgentState]:
        """Réconciliation d'état distribué avec résolution de conflits"""
        
        # Détection de conflits d'état
        conflicts = await self._detect_state_conflicts(agents_states)
        
        if not conflicts:
            return agents_states
        
        # Résolution de conflits par consensus
        resolved_states = {}
        
        for conflict in conflicts:
            resolution_strategy = await self._determine_resolution_strategy(conflict)
            
            if resolution_strategy == "consensus":
                resolved_state = await self.consensus_manager.resolve_by_voting(
                    conflict["affected_agents"], 
                    conflict["conflicting_data"]
                )
            elif resolution_strategy == "priority":
                resolved_state = await self._resolve_by_priority(conflict)
            elif resolution_strategy == "merge":
                resolved_state = await self.conflict_resolver.merge_states(
                    conflict["conflicting_states"]
                )
            
            # Application de la résolution
            for agent_id in conflict["affected_agents"]:
                resolved_states[agent_id] = resolved_state
        
        return resolved_states
```

## **Addendum 10 : Fault Tolerance pour Systèmes RAG Distribués**

### **Architecture de Tolérance aux Pannes Multi-Niveaux**
Basé sur les patterns de fault tolerance distribués[7][8][9], voici une implémentation robuste :

```python
class DistributedRAGFaultTolerance:
    def __init__(self):
        self.node_manager = NodeManager()
        self.replication_manager = ReplicationManager()
        self.health_monitor = HealthMonitor()
        self.failover_coordinator = FailoverCoordinator()
        
    async def execute_fault_tolerant_rag(
        self, 
        query: str, 
        required_nodes: int = 3,
        fault_tolerance_level: str = "high"
    ) -> Dict:
        """Exécution RAG avec tolérance aux pannes distribuée"""
        
        # Sélection de nœuds sains
        available_nodes = await self.node_manager.get_healthy_nodes()
        if len(available_nodes)  0,
                "consensus_confidence": final_result.get("confidence", 0.0)
            }
        }
    
    async def _execute_failover(
        self, 
        query: str, 
        failed_nodes: List[str], 
        execution_plan: Dict
    ) -> List[Dict]:
        """Exécution de failover intelligent"""
        
        # Sélection de nœuds de secours
        backup_nodes = await self.failover_coordinator.select_backup_nodes(
            failed_nodes, execution_plan["backup_nodes"]
        )
        
        # Réplication des données si nécessaire
        for backup_node in backup_nodes:
            await self.replication_manager.ensure_data_availability(
                backup_node, execution_plan["required_data"]
            )
        
        # Exécution sur nœuds de secours
        failover_results = await asyncio.gather(
            *[self._execute_on_node(node, query, execution_plan) 
              for node in backup_nodes],
            return_exceptions=True
        )
        
        return [r for r in failover_results if not isinstance(r, Exception)]
```

### **Pattern de Self-Healing RAG**
```python
class SelfHealingRAGSystem:
    def __init__(self):
        self.anomaly_detector = AnomalyDetector()
        self.auto_repairer = AutoRepairer()
        self.performance_optimizer = PerformanceOptimizer()
        
    async def self_healing_monitor(self):
        """Boucle de monitoring auto-réparatrice"""
        while True:
            try:
                # Collecte de métriques système
                system_metrics = await self._collect_system_metrics()
                
                # Détection d'anomalies
                anomalies = await self.anomaly_detector.detect_anomalies(system_metrics)
                
                for anomaly in anomalies:
                    # Auto-diagnostic
                    diagnosis = await self._diagnose_anomaly(anomaly)
                    
                    # Auto-réparation
                    if diagnosis["can_auto_repair"]:
                        repair_result = await self.auto_repairer.repair(
                            anomaly, diagnosis["repair_strategy"]
                        )
                        
                        if repair_result["success"]:
                            await self._log_successful_repair(anomaly, repair_result)
                        else:
                            await self._escalate_to_human(anomaly, repair_result)
                    else:
                        await self._escalate_to_human(anomaly, diagnosis)
                
                # Optimisation proactive
                await self.performance_optimizer.optimize_if_needed(system_metrics)
                
                await asyncio.sleep(30)  # Monitoring interval
                
            except Exception as e:
                await self._handle_monitor_failure(e)
                await asyncio.sleep(60)  # Backoff en cas d'erreur
    
    async def _diagnose_anomaly(self, anomaly: Dict) -> Dict:
        """Diagnostic intelligent d'anomalie"""
        diagnostic_prompt = f"""
        Analysez cette anomalie système et déterminez la stratégie de réparation :
        
        Anomalie : {anomaly}
        
        Répondez au format JSON :
        {{
            "root_cause": "description de la cause racine",
            "severity": "low|medium|high|critical",
            "can_auto_repair": true/false,
            "repair_strategy": "restart|scale|config_change|data_repair|manual",
            "estimated_repair_time": "durée estimée en minutes",
            "risk_assessment": "risque de la réparation automatique"
        }}
        """
        
        return await self.auto_repairer.diagnose(diagnostic_prompt)
```

Ces addendum fournissent des patterns concrets et éprouvés pour construire des systèmes RAG robustes et auto-adaptatifs. Chaque section inclut des exemples de code directement utilisables et des stratégies de mise en œuvre progressive, permettant aux équipes de développement d'implémenter ces techniques selon leurs besoins spécifiques et leur maturité technique[10][1][11][12][2][13][14][15][16][17].

[1] https://www.chitika.com/corrective-rag-langchain-langgraph/
[2] https://docs.llamaindex.ai/en/stable/examples/workflow/corrective_rag_pack/
[3] https://arxiv.org/html/2404.00640v2
[4] https://arxiv.org/html/2502.00677v1
[5] https://www.linkedin.com/pulse/why-do-we-need-state-management-ai-agents-tfb-the-flying-birds-ai-hem3c
[6] https://www.gocodeo.com/post/evaluating-memory-and-state-handling-in-leading-ai-agent-frameworks
[7] https://zilliz.com/ai-faq/how-do-distributed-databases-ensure-fault-tolerance
[8] https://www.tencentcloud.com/techpedia/105382
[9] https://www.chitika.com/scaling-rag-20-million-documents/
[10] https://vectorize.io/building-fault-tolerant-rag-pipelines-strategies-for-dealing-with-api-failures/
[11] https://aclanthology.org/2024.findings-acl.415/
[12] https://milvus.io/ai-quick-reference/how-do-i-handle-error-management-and-retries-in-langchain-workflows
[13] https://www.dailydoseofds.com/p/corrective-rag-agentic-workflow/
[14] https://blog.lancedb.com/implementing-corrective-rag-in-the-easiest-way-2/
[15] https://langchain-ai.github.io/langgraph/tutorials/rag/langgraph_crag/
[16] https://github.com/Kirouane-Ayoub/Corrective-RAG
[17] https://www.edenai.co/post/the-2025-guide-to-retrieval-augmented-generation-rag
[18] https://aclanthology.org/2025.coling-main.94/
[19] https://jxnl.co/writing/2025/06/11/rag-anti-patterns-with-skylar-payne/
[20] https://openreview.net/forum?id=NhIaRz9Qf5
[21] https://dev.to/shittu_olumide_/prompt-engineering-patterns-for-successful-rag-implementations-2m2e
[22] https://arxiv.org/abs/2403.14403
[23] https://arxiv.org/html/2407.12216v1
[24] https://fr.linkedin.com/posts/polynom-io_flashai-flashai-adaptiverag-activity-7241795560356130816-V5TW
[25] https://www.emergingtrajectories.com/blog/error-types-in-rag-for-research-automation-and-fact-verification
[26] https://arxiv.org/abs/2407.21712
[27] https://arxiv.org/html/2410.06949v2
[28] https://docs.databricks.com/aws/en/generative-ai/tutorials/ai-cookbook/evaluate-assess-performance
[29] https://aithority.com/machine-learning/self-healing-ai-systems-how-autonomous-ai-agents-detect-prevent-and-fix-operational-failures/
[30] https://convogenie.ai/blog/how-contextual-error-recovery-works-in-ai-agents
[31] https://orq.ai/blog/rag-evaluation
[32] https://economictimes.com/news/how-to/whats-self-healing-generative-ai-how-it-works-and-can-revolutionise-the-finance-sector/articleshow/111684165.cms
[33] https://www.geeksforgeeks.org/compiler-design/error-recovery-strategies-in-compiler-design/
[34] https://www.confident-ai.com/blog/rag-evaluation-metrics-answer-relevancy-faithfulness-and-more
[35] https://deepgram.com/ai-glossary/self-healing-ai
[36] https://www.kdnuggets.com/5-error-handling-patterns-in-python-beyond-try-except
[37] https://arize.com/blog-course/rag-evaluation/
[38] https://arxiv.org/abs/2504.20093
[39] https://helio.app/ux-research/ux-terms/ux-error-recovery/
[40] https://www.geeksforgeeks.org/nlp/evaluation-metrics-for-retrieval-augmented-generation-rag-systems/
[41] https://digitalisationworld.com/blogs/58272/ais-role-in-the-rise-of-self-healing-technologies
[42] https://www.eoinwoods.info/media/writing/EuroPLOP2004-error-handling.pdf
[43] https://www.pinecone.io/learn/series/vector-databases-in-production-for-busy-engineers/rag-evaluation/
[44] https://superagi.com/top-10-self-healing-ai-tools-to-watch-in-2024-a-comprehensive-review/
[45] https://www.reddit.com/r/ExperiencedDevs/comments/kty8bx/error_handling_patterns/
[46] https://qdrant.tech/blog/rag-evaluation-guide/
[47] https://deconstructing.ai/deconstructing-ai%E2%84%A2-blog/f/self-healing-ai-the-future-of-autonomous-resilience?blogcategory=Infrastructure
[48] https://middleware.io/blog/what-is-structured-logging/
[49] https://galileo.ai/blog/multi-agent-ai-system-failure-recovery
[50] https://milvus.io/ai-quick-reference/how-do-multiagent-systems-ensure-fault-tolerance
[51] https://apxml.com/courses/python-llm-workflows/chapter-9-testing-evaluating-llm-apps/logging-monitoring-llm-interactions
[52] https://docs.ray.io/en/latest/ray-core/fault-tolerance.html
[53] https://www.newline.co/@zaoyang/llm-based-error-detection-how-it-works--048a3eb9
[54] https://www.reddit.com/r/AI_Agents/comments/1k5e515/long_term_memory_in_ai_agent_applications/
[55] https://blog.premai.io/mastering-llm-observability-essential-practices-tools-and-future-trends-2/
[56] https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus
[57] https://ragaboutit.com/scaling-rag-for-big-data-techniques-and-strategies-for-handling-large-datasets/
[58] https://www.reddit.com/r/LangChain/comments/1d4tmdo/log_analyzer_using_llm/
[59] https://docs.ag-ui.com/concepts/state