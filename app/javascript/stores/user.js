import { defineStore } from "pinia";
import { ref } from "vue";

import { useTokenStore } from "./token";
import { useApplicationStore } from "./application";

export const useUserStore = defineStore("user", () => {
  const signedIn = ref(false);
  const email = ref("");

  function signOut() {
    const tokenStore = useTokenStore();
    tokenStore.signOut();

    const applicationStore = useApplicationStore();
    applicationStore.signOut();

    signedIn.value = false;
    email.value = "";
  }

  return { signedIn, email, signOut };
});
