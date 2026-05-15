/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    './src/main/resources/templates/**/*.{html,js}',
    './src/main/resources/static/**/*.{html,js}'
  ],
  theme: {
    extend: {
      colors: {
        primary: '#0c6780',      // Teal profundo
        'bg-light': '#f7f9fc',   // Gris azulado muy claro
        accent: '#87ceeb',       // Sky blue
        'sky-light': '#e0f6ff',
        'success': '#4ade80',
        'warning': '#fb923c',
        'danger': '#ef4444',
      },
      fontFamily: {
        'jakarta': ['Plus Jakarta Sans', 'sans-serif'],
        'work': ['Work Sans', 'sans-serif'],
      },
      boxShadow: {
        'glass': '0_4px_20px_rgba(135,206,235,0.1)',
        'elevation': '0 10px 30px rgba(12,103,128,0.12)',
      },
      borderRadius: {
        'xl': '16px',
        '2xl': '20px',
      },
      animation: {
        'fade-in': 'fadeIn 0.3s ease-in',
        'slide-in': 'slideIn 0.3s ease-out',
      },
      keyframes: {
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideIn: {
          '0%': { transform: 'translateY(10px)', opacity: '0' },
          '100%': { transform: 'translateY(0)', opacity: '1' },
        },
      },
    },
  },
  plugins: [],
}
