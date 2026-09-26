import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

import { useLongPress } from "../../mixins/use-long-press";

function pointerEvent(overrides = {}) {
  return { pointerType: "touch", clientX: 0, clientY: 0, ...overrides };
}

describe("useLongPress", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("fires after holding for the long-press duration", () => {
    const onLongPress = vi.fn();
    const { onPointerDown } = useLongPress(onLongPress);

    onPointerDown(pointerEvent());
    vi.advanceTimersByTime(499);
    expect(onLongPress).not.toHaveBeenCalled();

    vi.advanceTimersByTime(1);
    expect(onLongPress).toHaveBeenCalledTimes(1);
  });

  it("ignores the mouse pointer type (it already has hover and Ctrl/Cmd-click)", () => {
    const onLongPress = vi.fn();
    const { onPointerDown } = useLongPress(onLongPress);

    onPointerDown(pointerEvent({ pointerType: "mouse" }));
    vi.advanceTimersByTime(1000);

    expect(onLongPress).not.toHaveBeenCalled();
  });

  it("cancels on release before the threshold", () => {
    const onLongPress = vi.fn();
    const { onPointerDown, onPointerUp } = useLongPress(onLongPress);

    onPointerDown(pointerEvent());
    vi.advanceTimersByTime(200);
    onPointerUp();
    vi.advanceTimersByTime(1000);

    expect(onLongPress).not.toHaveBeenCalled();
  });

  it("cancels on pointercancel", () => {
    const onLongPress = vi.fn();
    const { onPointerDown, onPointerCancel } = useLongPress(onLongPress);

    onPointerDown(pointerEvent());
    onPointerCancel();
    vi.advanceTimersByTime(1000);

    expect(onLongPress).not.toHaveBeenCalled();
  });

  it("cancels on movement past the threshold (a scroll, not a press)", () => {
    const onLongPress = vi.fn();
    const { onPointerDown, onPointerMove } = useLongPress(onLongPress);

    onPointerDown(pointerEvent({ clientX: 0, clientY: 0 }));
    onPointerMove(pointerEvent({ clientX: 30, clientY: 0 }));
    vi.advanceTimersByTime(1000);

    expect(onLongPress).not.toHaveBeenCalled();
  });

  it("tolerates small jitter under the movement threshold", () => {
    const onLongPress = vi.fn();
    const { onPointerDown, onPointerMove } = useLongPress(onLongPress);

    onPointerDown(pointerEvent({ clientX: 0, clientY: 0 }));
    onPointerMove(pointerEvent({ clientX: 3, clientY: 3 }));
    vi.advanceTimersByTime(500);

    expect(onLongPress).toHaveBeenCalledTimes(1);
  });

  it("prevents the context menu while a press is in progress", () => {
    const { onPointerDown, onContextMenu } = useLongPress(() => {});
    const event = { preventDefault: vi.fn() };

    onPointerDown(pointerEvent());
    onContextMenu(event);

    expect(event.preventDefault).toHaveBeenCalled();
  });

  it("does not prevent the context menu outside a press", () => {
    const { onContextMenu } = useLongPress(() => {});
    const event = { preventDefault: vi.fn() };

    onContextMenu(event);

    expect(event.preventDefault).not.toHaveBeenCalled();
  });
});
