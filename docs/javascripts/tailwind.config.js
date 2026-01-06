tailwind.config = {
  important: true,
  corePlugins: {
    preflight: false,
  }
}

document$.subscribe(function() {
  const cloakedElements = document.querySelectorAll('.__cloak');
  
  setTimeout(() => {
    cloakedElements.forEach(el => {
      el.classList.add('__uncloak');
    });
  }, 150); 
});