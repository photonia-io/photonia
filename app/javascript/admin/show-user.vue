<template>
  <div>
    <div class="card">
      <div class="card-content">
        <div v-if="loading" class="has-text-centered">
          <p>Loading user...</p>
        </div>
        <div v-else-if="error" class="notification is-danger">
          <p>Error loading user: {{ error.message }}</p>
        </div>
        <div v-else-if="user">
          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">User ID</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input class="input" type="text" :value="user.id" readonly />
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Email</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="email"
                    :value="user.email"
                    readonly
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">First Name</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="text"
                    :value="user.firstName || '-'"
                    readonly
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Last Name</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="text"
                    :value="user.lastName || '-'"
                    readonly
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Display Name</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="text"
                    :value="user.displayName || '-'"
                    readonly
                  />
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Signup Provider</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <span
                    class="tag is-medium"
                    :class="{
                      'is-info': user.signupProvider === 'google',
                      'is-link': user.signupProvider === 'facebook',
                      'is-light': user.signupProvider === 'local',
                    }"
                  >
                    <span v-if="user.signupProvider === 'google'">
                      <i class="fab fa-google mr-2"></i>
                    </span>
                    <span v-if="user.signupProvider === 'facebook'">
                      <i class="fab fa-facebook mr-2"></i>
                    </span>
                    {{ user.signupProvider }}
                  </span>
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Admin</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <span v-if="user.admin" class="tag is-success is-medium"
                    >Yes</span
                  >
                  <span v-else class="tag is-medium">No</span>
                </div>
              </div>
            </div>
          </div>

          <div class="field is-horizontal">
            <div class="field-label is-normal">
              <label class="label">Timezone</label>
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <input
                    class="input"
                    type="text"
                    :value="user.timezone?.name || '-'"
                    readonly
                  />
                </div>
              </div>
            </div>
          </div>

          <!-- Pending Flickr Claims Section -->
          <div v-if="user.pendingFlickrClaims && user.pendingFlickrClaims.length > 0">
            <hr />
            <h2 class="title is-4">Pending Flickr Claims</h2>
            <div
              v-for="claim in user.pendingFlickrClaims"
              :key="claim.id"
              class="box"
            >
              <div class="content">
                <p>
                  <strong>Flickr Username:</strong>
                  <a
                    :href="claim.flickrUser.profileurl"
                    target="_blank"
                    rel="noopener"
                  >
                    {{ claim.flickrUser.username }}
                  </a>
                  <span v-if="claim.flickrUser.realname">
                    ({{ claim.flickrUser.realname }})
                  </span>
                </p>
                <p><strong>Flickr NSID:</strong> {{ claim.flickrUser.nsid }}</p>
                <p><strong>Claim Type:</strong> {{ claim.claimType }}</p>
                <p v-if="claim.reason">
                  <strong>Reason:</strong> {{ claim.reason }}
                </p>
                <p>
                  <strong>Requested:</strong>
                  {{ new Date(claim.createdAt).toLocaleString() }}
                </p>
              </div>
              <div class="buttons">
                <button
                  class="button is-success"
                  :class="{ 'is-loading': approvingClaim === claim.id }"
                  :disabled="approvingClaim || denyingClaim"
                  @click="approveClaim(claim.id)"
                >
                  <span class="icon">
                    <i class="fas fa-check"></i>
                  </span>
                  <span>Approve</span>
                </button>
                <button
                  class="button is-danger"
                  :class="{ 'is-loading': denyingClaim === claim.id }"
                  :disabled="approvingClaim || denyingClaim"
                  @click="denyClaim(claim.id)"
                >
                  <span class="icon">
                    <i class="fas fa-times"></i>
                  </span>
                  <span>Deny</span>
                </button>
              </div>
            </div>
          </div>

          <hr />
          <div class="field is-horizontal">
            <div class="field-label">
              <!-- Left empty for spacing -->
            </div>
            <div class="field-body">
              <div class="field">
                <div class="control">
                  <button class="button" @click="goBack">
                    <span>Back to Users</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { computed, ref } from "vue";
import { useRoute, useRouter } from "vue-router";
import gql from "graphql-tag";
import { useQuery, useMutation } from "@vue/apollo-composable";
import { useToast } from "vue-toastification";

const route = useRoute();
const router = useRouter();
const toast = useToast();

const approvingClaim = ref(null);
const denyingClaim = ref(null);

const USER_QUERY = gql`
  query UserQuery($id: String!) {
    user(id: $id) {
      id
      email
      firstName
      lastName
      displayName
      signupProvider
      admin
      timezone {
        name
      }
      pendingFlickrClaims {
        id
        flickrUser {
          id
          nsid
          username
          realname
          profileurl
        }
        claimType
        reason
        createdAt
      }
    }
  }
`;

const { result, loading, error, refetch } = useQuery(USER_QUERY, {
  id: route.params.id,
});

const user = computed(() => result.value?.user);

const APPROVE_FLICKR_CLAIM = gql`
  mutation ApproveFlickrClaim($claimId: ID!) {
    approveFlickrClaim(claimId: $claimId) {
      success
      errors
      claim {
        id
        status
      }
    }
  }
`;

const DENY_FLICKR_CLAIM = gql`
  mutation DenyFlickrClaim($claimId: ID!) {
    denyFlickrClaim(claimId: $claimId) {
      success
      errors
      claim {
        id
        status
      }
    }
  }
`;

const { mutate: approveFlickrClaimMutation } = useMutation(
  APPROVE_FLICKR_CLAIM
);
const { mutate: denyFlickrClaimMutation } = useMutation(DENY_FLICKR_CLAIM);

const approveClaim = async (claimId) => {
  approvingClaim.value = claimId;
  try {
    const result = await approveFlickrClaimMutation({ claimId });
    if (result.data.approveFlickrClaim.success) {
      toast.success("Flickr claim approved successfully");
      await refetch();
    } else {
      toast.error(
        result.data.approveFlickrClaim.errors.join(", ") ||
          "Failed to approve claim"
      );
    }
  } catch (err) {
    toast.error("Error approving claim: " + err.message);
  } finally {
    approvingClaim.value = null;
  }
};

const denyClaim = async (claimId) => {
  denyingClaim.value = claimId;
  try {
    const result = await denyFlickrClaimMutation({ claimId });
    if (result.data.denyFlickrClaim.success) {
      toast.success("Flickr claim denied successfully");
      await refetch();
    } else {
      toast.error(
        result.data.denyFlickrClaim.errors.join(", ") || "Failed to deny claim"
      );
    }
  } catch (err) {
    toast.error("Error denying claim: " + err.message);
  } finally {
    denyingClaim.value = null;
  }
};

const goBack = () => {
  router.push({ name: "admin-users" });
};
</script>
