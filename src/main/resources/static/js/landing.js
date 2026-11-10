
document.addEventListener("DOMContentLoaded", () => {
    // 🎯 CURSOR PERSONALIZADO
    const cursor = document.querySelector('.custom-cursor');
    const follower = document.querySelector('.cursor-follower');

    if (cursor && follower) {
        document.addEventListener('mousemove', (e) => {
            cursor.style.left = e.clientX + 'px';
            cursor.style.top = e.clientY + 'px';

            setTimeout(() => {
                follower.style.left = e.clientX + 'px';
                follower.style.top = e.clientY + 'px';
            }, 100);
        });

        document.addEventListener('mousedown', () => {
            cursor.style.transform = 'scale(0.8)';
            follower.style.transform = 'scale(1.2)';
        });

        document.addEventListener('mouseup', () => {
            cursor.style.transform = 'scale(1)';
            follower.style.transform = 'scale(1)';
        });
    }

    // 📊 SCROLL PROGRESS BAR
    const progressBar = document.querySelector('.scroll-progress');
    const navbar = document.querySelector('.menu-bar');

    window.addEventListener('scroll', () => {
        const totalHeight = document.documentElement.scrollHeight - window.innerHeight;
        const progress = (window.pageYOffset / totalHeight) * 100;
        if (progressBar) progressBar.style.width = progress + '%';

        if (navbar) {
            if (window.scrollY > 100) navbar.classList.add('scrolled');
            else navbar.classList.remove('scrolled');
        }
    });

    // 🌌 PARTÍCULAS
    function createParticles() {
        const container = document.querySelector('.particles');
        if (!container) return;
        for (let i = 0; i < 30; i++) {
            const p = document.createElement('div');
            p.className = 'particle';
            p.style.left = Math.random() * 100 + 'vw';
            p.style.top = Math.random() * 100 + 'vh';
            p.style.animationDelay = Math.random() * 10 + 's';
            p.style.animationDuration = (Math.random() * 8 + 12) + 's';
            container.appendChild(p);
        }
    }

    createParticles();

    // 🎯 SCROLL SUAVE
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({ behavior: 'smooth', block: 'start' });
            }
        });
    });

    // 🌟 ANIMACIONES DE SCROLL (Fallback)
    if (!CSS.supports('view-timeline', '--test')) {
        const sections = document.querySelectorAll('.scroll-section');
        sections.forEach((section, index) => {
            section.style.animationDelay = `${index * 0.2}s`;
        });

        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.style.opacity = '1';
                    entry.target.style.transform = 'scale(1) translateY(0)';
                }
            });
        }, { threshold: 0.3 });

        document.querySelectorAll('.scroll-section').forEach(section => {
            observer.observe(section);
        });
    }
});

