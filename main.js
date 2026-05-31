// Navbar scroll effect
const navbar = document.getElementById('navbar');
window.addEventListener('scroll', () => {
  navbar.classList.toggle('scrolled', window.scrollY > 60);
});

// Mobile menu toggle
const menuToggle = document.getElementById('menuToggle');
const navLinks = document.getElementById('navLinks');
menuToggle.addEventListener('click', () => {
  navLinks.classList.toggle('open');
});
navLinks.querySelectorAll('a').forEach(link => {
  link.addEventListener('click', () => navLinks.classList.remove('open'));
});

// Set today's date in prayer section
const dateEl = document.getElementById('prayerDate');
if (dateEl) {
  dateEl.textContent = new Date().toLocaleDateString('en-GB', {
    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric'
  });
}

// Highlight the current / next prayer
(function highlightPrayer() {
  const now = new Date();
  const minutes = now.getHours() * 60 + now.getMinutes();

  // [name, adhan hour, adhan minute]
  const prayers = [
    ['fajr',    5,  12],
    ['dhuhr',  13,  15],
    ['asr',    16,  45],
    ['maghrib',19,  52],
    ['isha',   21,  20],
  ];

  let activeIndex = prayers.length - 1;
  for (let i = 0; i < prayers.length; i++) {
    const [, h, m] = prayers[i];
    if (minutes < h * 60 + m) { activeIndex = i === 0 ? prayers.length - 1 : i - 1; break; }
    activeIndex = i;
  }

  const activeCard = document.querySelector(`[data-prayer="${prayers[activeIndex][0]}"]`);
  if (activeCard) activeCard.classList.add('active');
})();

// Contact form submission
const form = document.getElementById('contactForm');
const successMsg = document.getElementById('formSuccess');
if (form) {
  form.addEventListener('submit', (e) => {
    e.preventDefault();
    successMsg.classList.add('show');
    form.reset();
    setTimeout(() => successMsg.classList.remove('show'), 5000);
  });
}

// Scroll-in animation
const observer = new IntersectionObserver((entries) => {
  entries.forEach(entry => {
    if (entry.isIntersecting) {
      entry.target.style.opacity = '1';
      entry.target.style.transform = 'translateY(0)';
      observer.unobserve(entry.target);
    }
  });
}, { threshold: 0.1 });

document.querySelectorAll('.prayer-card, .event-card, .contact-item, .stat').forEach(el => {
  el.style.opacity = '0';
  el.style.transform = 'translateY(20px)';
  el.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
  observer.observe(el);
});
