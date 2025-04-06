// Toggle sidebar
document.querySelector('.menu-toggle').addEventListener('click', function() {
  document.querySelector('.sidebar').classList.toggle('collapsed');
  document.querySelector('.container').classList.toggle('sidebar-collapsed');
});

// Simulate loading data
document.addEventListener('DOMContentLoaded', function() {
  // Add pulse animation to action button
  document.querySelector('.action-button').classList.add('animate-pulse');
  
  // Add hover effects to cards
  const cards = document.querySelectorAll('.dashboard-card');
  cards.forEach(card => {
    card.addEventListener('mouseenter', function() {
      this.style.transform = 'translateY(-5px)';
      this.style.boxShadow = '0 8px 15px rgba(0, 0, 0, 0.1)';
    });
    
    card.addEventListener('mouseleave', function() {
      this.style.transform = 'translateY(0)';
      this.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.05)';
    });
  });
  
  // Add click event to entries
  const entries = document.querySelectorAll('.entry-item');
  entries.forEach(entry => {
    entry.addEventListener('click', function() {
      // Simulate navigation
      this.style.backgroundColor = 'rgba(67, 97, 238, 0.1)';
      setTimeout(() => {
        alert('Navigation vers l\'entrée: ' + this.querySelector('h3').textContent);
        this.style.backgroundColor = '';
      }, 300);
    });
  });
  
  // Responsive sidebar toggle
  if (window.innerWidth <= 768) {
    document.querySelector('.menu-toggle').addEventListener('click', function() {
      document.querySelector('.sidebar').classList.toggle('show');
    });
  }
});
