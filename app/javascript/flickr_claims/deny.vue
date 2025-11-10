<template>
  <div class="container">
    <div class="section">
      <div class="box has-text-centered">
        <div class="icon-text is-flex-direction-column">
          <span class="icon has-text-danger is-size-1 mb-4">
            <i class="fas fa-times-circle"></i>
          </span>
          <h1 class="title is-3 has-text-danger">Claim Denied</h1>
        </div>
        <p class="mt-4">
          The Flickr user claim has been denied. The user has been notified.
        </p>
        <div class="mt-5">
          <router-link to="/" class="button is-primary">
            <span class="icon">
              <i class="fas fa-home"></i>
            </span>
            <span>Go to Homepage</span>
          </router-link>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { onMounted } from "vue";
import { useRoute } from "vue-router";
import { useApplicationStore } from "@/stores/application";
import toaster from "@/mixins/toaster";

const route = useRoute();
const applicationStore = useApplicationStore();

onMounted(async () => {
  const claimId = route.query.claim_id;
  const token = route.query.token;

  if (!claimId || !token) {
    toaster("Invalid denial link", "is-danger");
    return;
  }

  applicationStore.loading = true;
  
  try {
    // Call the Rails endpoint to deny the claim
    const response = await fetch(`/flickr_claims/deny?claim_id=${claimId}&token=${encodeURIComponent(token)}`, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    if (!response.ok) {
      const data = await response.json();
      toaster(data.error || "Failed to deny claim", "is-danger");
    }
  } catch (error) {
    console.error('Error denying claim:', error);
    toaster("An error occurred while denying the claim", "is-danger");
  } finally {
    applicationStore.loading = false;
  }
});
</script>
