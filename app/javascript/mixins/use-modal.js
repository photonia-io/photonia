import { nextTick, onUnmounted, ref } from "vue";
import { useApplicationStore } from "../stores/application";

// Shared lifecycle for a teleported Bulma modal: Escape closes it, photo
// navigation shortcuts are suspended while it's open, and the modal card
// gets focus on open. Callers handle focusing their own trigger on close.
export function useModal({ onClose } = {}) {
  const applicationStore = useApplicationStore();

  const active = ref(false);
  const modalCard = ref(null);

  const handleKeydown = (event) => {
    if (event.key === "Escape") {
      close();
    }
  };

  const open = () => {
    active.value = true;
    applicationStore.disableNavigationShortcuts();
    document.addEventListener("keydown", handleKeydown);
    nextTick(() => {
      modalCard.value?.focus();
    });
  };

  const close = () => {
    active.value = false;
    applicationStore.enableNavigationShortcuts();
    document.removeEventListener("keydown", handleKeydown);
    onClose?.();
  };

  onUnmounted(() => {
    if (active.value) {
      applicationStore.enableNavigationShortcuts();
      document.removeEventListener("keydown", handleKeydown);
    }
  });

  return { active, modalCard, open, close };
}
