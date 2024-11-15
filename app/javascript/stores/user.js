import { defineStore } from "pinia";
import { ref } from "vue";

import { useTokenStore } from "./token";
import { useApplicationStore } from "./application";

export const useUserStore = defineStore("user", () => {
  const signedIn = ref(false);
  const email = ref("");
  const admin = ref(false);
  const uploader = ref(false);

  function signOut() {
    const tokenStore = useTokenStore();
    tokenStore.signOut();

    const applicationStore = useApplicationStore();
    applicationStore.signOut();

    signedIn.value = false;
    email.value = "";
    admin.value = false;
    uploader.value = false;
  }

  return { signedIn, email, admin, uploader, signOut };
});
