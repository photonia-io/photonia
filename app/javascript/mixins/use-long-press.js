import { ref } from "vue";

const LONG_PRESS_MS = 500;
const MOVE_THRESHOLD_PX = 10;

// Long-press-to-select, built on Pointer Events so mouse, touch and pen
// share one path. Mouse is ignored here since it already has hover and
// Ctrl/Cmd-click. Cancels on movement past the threshold so a scroll
// gesture never fires it, and flags contextmenu so callers can suppress
// Android's image-save popup while a press is in progress.
export function useLongPress(onLongPress) {
  const pressing = ref(false);

  let timer = null;
  let startX = 0;
  let startY = 0;

  function clear() {
    if (timer) {
      clearTimeout(timer);
      timer = null;
    }
    pressing.value = false;
  }

  function onPointerDown(event) {
    if (event.pointerType === "mouse") return;

    startX = event.clientX;
    startY = event.clientY;
    pressing.value = true;

    timer = setTimeout(() => {
      timer = null;
      onLongPress(event);
    }, LONG_PRESS_MS);
  }

  function onPointerMove(event) {
    if (!pressing.value) return;

    const dx = event.clientX - startX;
    const dy = event.clientY - startY;
    if (Math.hypot(dx, dy) > MOVE_THRESHOLD_PX) clear();
  }

  function onPointerUp() {
    clear();
  }

  function onPointerCancel() {
    clear();
  }

  function onContextMenu(event) {
    if (pressing.value) event.preventDefault();
  }

  return {
    pressing,
    onPointerDown,
    onPointerMove,
    onPointerUp,
    onPointerCancel,
    onContextMenu,
  };
}
