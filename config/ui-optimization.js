// UI Performance Optimization Patterns

// Efficient DOM Manipulation
class DOMOptimizer {
    static batchUpdate(callback) {
        requestAnimationFrame(() => {
            const fragment = document.createDocumentFragment();
            callback(fragment);
            document.body.appendChild(fragment);
        });
    }
    
    static debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }
    
    static throttle(func, limit) {
        let inThrottle;
        return function(...args) {
            if (!inThrottle) {
                func.apply(this, args);
                inThrottle = true;
                setTimeout(() => inThrottle = false, limit);
            }
        };
    }
}

// Memory-Efficient Event Handling
class EventOptimizer {
    constructor() {
        this.listeners = new WeakMap();
    }
    
    addPassiveListener(element, event, handler) {
        element.addEventListener(event, handler, { 
            passive: true, 
            capture: false 
        });
        this.listeners.set(element, { event, handler });
    }
    
    cleanup(element) {
        const listener = this.listeners.get(element);
        if (listener) {
            element.removeEventListener(listener.event, listener.handler);
            this.listeners.delete(element);
        }
    }
}

// Progressive Loading Manager
class ProgressiveLoader {
    static loadComponent(importFn) {
        return new Promise((resolve) => {
            requestIdleCallback(() => {
                importFn().then(resolve);
            }, { timeout: 100 });
        });
    }
    
    static observeVisibility(element, callback) {
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    callback(entry.target);
                    observer.unobserve(entry.target);
                }
            });
        }, { rootMargin: '50px' });
        
        observer.observe(element);
        return observer;
    }
}

// Export optimizers
window.UIOptimizers = {
    DOM: DOMOptimizer,
    Event: EventOptimizer,
    Progressive: ProgressiveLoader
};
