<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">Stats</h1>
      <hr class="mt-2 mb-4" />
      <Line
        v-if="chartData"
        :data="chartData"
        :options="chartOptions"
        style="max-height: 60vh"
      />

      <p v-if="!selectedDate" class="has-text-grey mt-4">
        Click a date on the chart to see its most viewed photos and albums.
      </p>
      <div v-else class="mt-5">
        <h2 class="title is-5">Most viewed on {{ niceDate }}</h2>
        <div class="columns">
          <div class="column">
            <h3 class="subtitle is-6">Photos</h3>
            <p v-if="!mostViewed?.photos.length" class="has-text-grey">
              No views
            </p>
            <article
              v-for="entry in mostViewed?.photos"
              :key="entry.photo.id"
              class="media"
            >
              <figure class="media-left">
                <router-link
                  :to="{ name: 'photos-show', params: { id: entry.photo.id } }"
                  class="image is-48x48"
                >
                  <img
                    :src="entry.photo.intelligentOrSquareMediumImageUrl"
                    :alt="entry.photo.title"
                  />
                </router-link>
              </figure>
              <div class="media-content">
                <router-link
                  :to="{ name: 'photos-show', params: { id: entry.photo.id } }"
                >
                  {{ entry.photo.title }}
                </router-link>
                <p class="is-size-7 has-text-grey">{{ views(entry.count) }}</p>
              </div>
            </article>
          </div>
          <div class="column">
            <h3 class="subtitle is-6">Albums</h3>
            <p v-if="!mostViewed?.albums.length" class="has-text-grey">
              No views
            </p>
            <article
              v-for="entry in mostViewed?.albums"
              :key="entry.album.id"
              class="media"
            >
              <figure class="media-left">
                <router-link
                  :to="{ name: 'albums-show', params: { id: entry.album.id } }"
                  class="image is-48x48"
                >
                  <img
                    v-if="entry.album.coverPhoto"
                    :src="entry.album.coverPhoto.intelligentOrSquareMediumImageUrl"
                    :alt="entry.album.title"
                  />
                </router-link>
              </figure>
              <div class="media-content">
                <router-link
                  :to="{ name: 'albums-show', params: { id: entry.album.id } }"
                >
                  {{ entry.album.title }}
                </router-link>
                <p class="is-size-7 has-text-grey">{{ views(entry.count) }}</p>
              </div>
            </article>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, ref } from "vue";
import { useQuery } from "@vue/apollo-composable";
import { gql } from "graphql-tag";
import { useTitle } from "vue-page-title";
import { storeToRefs } from "pinia";

import { Line } from "vue-chartjs";

import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
} from "chart.js";

import { useApplicationStore } from "@/stores/application";

useTitle("Stats");

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
);

const { colorScheme } = storeToRefs(useApplicationStore());

const startDate = new Date();
startDate.setDate(startDate.getDate() - 30);
const endDate = new Date();

const { result } = useQuery(
  gql`
    query StatsQuery($startDate: ISO8601DateTime!, $endDate: ISO8601DateTime!) {
      photoImpressionCountsByDate: impressionCountsByDate(
        type: "Photo"
        startDate: $startDate
        endDate: $endDate
      ) {
        date
        count
      }
      albumImpressionCountsByDate: impressionCountsByDate(
        type: "Album"
        startDate: $startDate
        endDate: $endDate
      ) {
        date
        count
      }
    }
  `,
  {
    startDate: startDate.toISOString(),
    endDate: endDate.toISOString(),
  },
);

const selectedDate = ref(null);

const { result: mostViewedResult } = useQuery(
  gql`
    query MostViewedOnDate($date: ISO8601Date!) {
      mostViewedOnDate(date: $date) {
        photos {
          count
          photo {
            id
            title
            intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
          }
        }
        albums {
          count
          album {
            id
            title
            coverPhoto {
              intelligentOrSquareMediumImageUrl: imageUrl(type: "medium")
            }
          }
        }
      }
    }
  `,
  () => ({ date: selectedDate.value }),
  () => ({ enabled: !!selectedDate.value }),
);

const mostViewed = computed(() => mostViewedResult.value?.mostViewedOnDate);

const niceDate = computed(() => {
  const [year, month, day] = selectedDate.value.split("-").map(Number);
  return new Date(year, month - 1, day).toLocaleDateString("en-US", {
    weekday: "long",
    month: "long",
    day: "numeric",
    year: "numeric",
  });
});

const views = (count) => `${count} ${count === 1 ? "view" : "views"}`;

const palette = computed(() =>
  colorScheme.value === "dark"
    ? { text: "#e0e0e0", grid: "rgba(255, 255, 255, 0.15)" }
    : { text: "#4a4a4a", grid: "rgba(0, 0, 0, 0.1)" },
);

const chartOptions = computed(() => ({
  responsive: true,
  color: palette.value.text,
  interaction: { mode: "index", intersect: false },
  onClick: (_event, elements, chart) => {
    if (elements.length) selectedDate.value = chart.data.labels[elements[0].index];
  },
  onHover: (event, elements) => {
    const target = event.native?.target;
    if (target) target.style.cursor = elements.length ? "pointer" : "default";
  },
  scales: {
    x: {
      ticks: { color: palette.value.text },
      grid: { color: palette.value.grid },
    },
    y: {
      ticks: { color: palette.value.text },
      grid: { color: palette.value.grid },
    },
  },
}));

// convert response to chart.js format
const chartData = computed(() => {
  const photoData = result.value?.photoImpressionCountsByDate;
  const albumData = result.value?.albumImpressionCountsByDate;

  if (!photoData) return;

  return {
    labels: photoData.map((d) => d.date),
    datasets: [
      {
        label: "Photo Views",
        backgroundColor: "#f87979",
        borderColor: "#f87979",
        data: photoData.map((d) => d.count),
      },
      {
        label: "Album Views",
        backgroundColor: "#7f7fff",
        borderColor: "#7f7fff",
        data: albumData.map((d) => d.count),
      },
    ],
  };
});
</script>

<style scoped>
.media img {
  object-fit: cover;
  width: 100%;
  height: 100%;
  border-radius: 0.3rem;
}
</style>
