function toggleCommand(id, checkbox) {
  const cmd = document.getElementById(id);
  if (cmd) {
    cmd.style.display = checkbox.checked ? 'block' : 'none';
  }
}

mermaid.run({
    querySelector: ".mermaid"
});