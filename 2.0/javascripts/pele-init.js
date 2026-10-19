// Render ```mermaid fences (emitted as <pre class="pele">) with Pele instead of Mermaid.
function renderPele() {
  document.querySelectorAll("pre.pele").forEach((pre) => {
    const source = pre.textContent;
    const div = document.createElement("div");
    div.className = "pele-diagram";
    pre.replaceWith(div);
    pele.mount(div, source);
  });
}
if (typeof document$ !== "undefined") document$.subscribe(renderPele);
else document.addEventListener("DOMContentLoaded", renderPele);
