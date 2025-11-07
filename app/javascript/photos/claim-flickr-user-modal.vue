<template>
  <teleport to="#modal-root">
    <div :class="['modal', isActive ? 'is-active' : null]">
      <div class="modal-background" @click="closeModal"></div>
      <div class="modal-card" style="max-width: 600px">
        <header class="modal-card-head">
          <p class="modal-card-title">Claim Flickr User</p>
          <button
            class="delete"
            aria-label="close"
            @click="closeModal"
          ></button>
        </header>
        <div class="modal-card-body">
          <!-- Automatic Claim Section -->
          <div v-if="!showManualForm">
            <div class="content">
              <p class="mb-4">
                <strong>Claim {{ flickrUsername }}</strong>
              </p>
              
              <div v-if="!claim">
                <p>
                  To claim this Flickr user automatically, we'll generate a
                  verification code that you'll need to temporarily add to your
                  Flickr profile.
                </p>
                <div class="buttons mt-4">
                  <button
                    class="button is-primary"
                    @click="requestAutomaticClaim"
                    :disabled="requesting"
                  >
                    <span v-if="!requesting">Start Verification</span>
                    <span v-else>Requesting...</span>
                  </button>
                </div>
              </div>

              <div v-else-if="claim && !claim.verificationCode">
                <div class="notification is-warning">
                  <p>Loading claim details...</p>
                </div>
              </div>

              <div v-else>
                <div class="box has-background-info-light mb-4">
                  <p class="mb-3">
                    <strong>Your verification code:</strong>
                  </p>
                  <p class="is-family-monospace is-size-4 has-text-weight-bold mb-3">
                    {{ claim.verificationCode }}
                  </p>
                  <button
                    class="button is-small is-info"
                    @click="copyToClipboard"
                  >
                    <span class="icon"><i class="fas fa-copy"></i></span>
                    <span>{{ copied ? 'Copied!' : 'Copy Code' }}</span>
                  </button>
                </div>

                <div class="content">
                  <p><strong>Instructions:</strong></p>
                  <ol>
                    <li>
                      Open your
                      <a
                        :href="flickrProfileEditUrl"
                        target="_blank"
                        rel="noopener noreferrer"
                      >
                        Flickr profile settings
                        <span class="icon is-small">
                          <i class="fas fa-external-link-alt"></i>
                        </span>
                      </a>
                    </li>
                    <li>
                      Add the verification code above to the first field
                      ("Describe yourself") on that page
                    </li>
                    <li>Save your Flickr profile changes</li>
                    <li>Come back here and click the "Verify" button below</li>
                  </ol>
                </div>

                <div v-if="verificationError" class="notification is-danger">
                  {{ verificationError }}
                </div>

                <div v-if="verificationSuccess" class="notification is-success">
                  <p>
                    <strong>Success!</strong> Your claim has been approved. You
                    can now remove the verification code from your Flickr
                    profile.
                  </p>
                </div>

                <div class="buttons mt-4">
                  <button
                    class="button is-success"
                    @click="verifyAutomaticClaim"
                    :disabled="verifying || verificationSuccess"
                  >
                    <span v-if="!verifying">Verify</span>
                    <span v-else>Verifying...</span>
                  </button>
                </div>
              </div>
            </div>

            <hr />

            <div class="has-text-centered">
              <p class="is-size-7">
                Lost access to your Flickr account? You can also
                <a @click="showManualForm = true" class="has-text-link">
                  claim your user manually
                </a>
                .
              </p>
            </div>
          </div>

          <!-- Manual Claim Section -->
          <div v-else>
            <div class="content">
              <p class="mb-4">
                <strong>Request Manual Claim</strong>
              </p>
              <p>
                If you've lost access to your Flickr account, you can request a
                manual claim. An administrator will review your request.
              </p>

              <div class="field mt-4">
                <label class="label">Reason (optional)</label>
                <div class="control">
                  <textarea
                    class="textarea"
                    v-model="manualReason"
                    placeholder="Explain why you need a manual claim (e.g., lost account access)"
                    rows="4"
                  ></textarea>
                </div>
              </div>

              <div v-if="manualError" class="notification is-danger">
                {{ manualError }}
              </div>

              <div v-if="manualSuccess" class="notification is-success">
                <p>
                  <strong>Request submitted!</strong> An administrator will
                  review your claim and notify you via email.
                </p>
              </div>

              <div class="buttons mt-4">
                <button
                  class="button is-primary"
                  @click="requestManualClaim"
                  :disabled="requestingManual || manualSuccess"
                >
                  <span v-if="!requestingManual">Submit Request</span>
                  <span v-else>Submitting...</span>
                </button>
                <button
                  class="button"
                  @click="showManualForm = false"
                  :disabled="requestingManual"
                >
                  Back to Automatic
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </teleport>
</template>

<script setup>
import { ref, computed, watch } from "vue";
import { useMutation } from "@vue/apollo-composable";
import gql from "graphql-tag";

const props = defineProps({
  flickrUser: {
    type: Object,
    required: true,
  },
  isActive: {
    type: Boolean,
    required: true,
  },
});

const emit = defineEmits(["close", "claimed"]);

const showManualForm = ref(false);
const claim = ref(null);
const requesting = ref(false);
const verifying = ref(false);
const verificationError = ref(null);
const verificationSuccess = ref(false);
const copied = ref(false);
const manualReason = ref("");
const requestingManual = ref(false);
const manualError = ref(null);
const manualSuccess = ref(false);

const flickrUsername = computed(() => {
  return (
    props.flickrUser.realname ||
    props.flickrUser.username ||
    props.flickrUser.nsid
  );
});

const flickrProfileEditUrl = computed(() => {
  return `https://www.flickr.com/profile_edit.gne`;
});

// Reset state when modal is closed/opened
watch(
  () => props.isActive,
  (newVal) => {
    if (!newVal) {
      // Reset state when closing
      setTimeout(() => {
        showManualForm.value = false;
        claim.value = null;
        requesting.value = false;
        verifying.value = false;
        verificationError.value = null;
        verificationSuccess.value = false;
        copied.value = false;
        manualReason.value = "";
        requestingManual.value = false;
        manualError.value = null;
        manualSuccess.value = false;
      }, 300);
    }
  }
);

const {
  mutate: requestAutomaticClaimMutation,
  onDone: onRequestAutomaticClaimDone,
  onError: onRequestAutomaticClaimError,
} = useMutation(gql`
  mutation ($flickrUserNsid: String!) {
    requestAutomaticFlickrClaim(flickrUserNsid: $flickrUserNsid) {
      claim {
        id
        verificationCode
      }
      errors
    }
  }
`);

const {
  mutate: verifyAutomaticClaimMutation,
  onDone: onVerifyAutomaticClaimDone,
  onError: onVerifyAutomaticClaimError,
} = useMutation(gql`
  mutation ($claimId: ID!) {
    verifyAutomaticFlickrClaim(claimId: $claimId) {
      success
      claim {
        id
        status
      }
      errors
    }
  }
`);

const {
  mutate: requestManualClaimMutation,
  onDone: onRequestManualClaimDone,
  onError: onRequestManualClaimError,
} = useMutation(gql`
  mutation ($flickrUserNsid: String!, $reason: String) {
    requestManualFlickrClaim(
      flickrUserNsid: $flickrUserNsid
      reason: $reason
    ) {
      claim {
        id
        status
      }
      errors
    }
  }
`);

function requestAutomaticClaim() {
  requesting.value = true;
  verificationError.value = null;
  requestAutomaticClaimMutation({
    flickrUserNsid: props.flickrUser.nsid,
  });
}

onRequestAutomaticClaimDone((result) => {
  requesting.value = false;
  if (result.data.requestAutomaticFlickrClaim.errors.length > 0) {
    verificationError.value =
      result.data.requestAutomaticFlickrClaim.errors.join(", ");
  } else {
    claim.value = result.data.requestAutomaticFlickrClaim.claim;
  }
});

onRequestAutomaticClaimError((error) => {
  requesting.value = false;
  verificationError.value = "Failed to request claim. Please try again.";
  console.error(error);
});

function verifyAutomaticClaim() {
  verifying.value = true;
  verificationError.value = null;
  verifyAutomaticClaimMutation({
    claimId: claim.value.id,
  });
}

onVerifyAutomaticClaimDone((result) => {
  verifying.value = false;
  if (result.data.verifyAutomaticFlickrClaim.success) {
    verificationSuccess.value = true;
    setTimeout(() => {
      emit("claimed");
      closeModal();
    }, 3000);
  } else {
    verificationError.value =
      result.data.verifyAutomaticFlickrClaim.errors.join(", ");
  }
});

onVerifyAutomaticClaimError((error) => {
  verifying.value = false;
  verificationError.value = "Failed to verify claim. Please try again.";
  console.error(error);
});

function requestManualClaim() {
  requestingManual.value = true;
  manualError.value = null;
  requestManualClaimMutation({
    flickrUserNsid: props.flickrUser.nsid,
    reason: manualReason.value || null,
  });
}

onRequestManualClaimDone((result) => {
  requestingManual.value = false;
  if (result.data.requestManualFlickrClaim.errors.length > 0) {
    manualError.value =
      result.data.requestManualFlickrClaim.errors.join(", ");
  } else {
    manualSuccess.value = true;
    setTimeout(() => {
      closeModal();
    }, 3000);
  }
});

onRequestManualClaimError((error) => {
  requestingManual.value = false;
  manualError.value = "Failed to submit manual claim request. Please try again.";
  console.error(error);
});

function copyToClipboard() {
  navigator.clipboard.writeText(claim.value.verificationCode).then(() => {
    copied.value = true;
    setTimeout(() => {
      copied.value = false;
    }, 2000);
  });
}

function closeModal() {
  emit("close");
}
</script>

<style scoped>
.modal-card {
  max-height: 90vh;
  overflow-y: auto;
}
</style>
