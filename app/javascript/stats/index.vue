<template>
  <section class="section-pt-pb-0">
    <div class="container">
      <h1 class="title mt-5 mb-0">Stats</h1>
      <hr class="mt-2 mb-4" />
      <Line
        :data="chartData"
        v-if="chartData"
        style="max-height: 60vh"
        chartOptions="{ responsive: true }"
      />
    </div>
  </section>
</template>

<script setup>
import { computed } from "vue";
import { useQuery } from "@vue/apollo-composable";
import { gql } from "graphql-tag";
import { useTitle } from "vue-page-title";

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

useTitle("Stats");

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend
);

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
      tagImpressionCountsByDate: impressionCountsByDate(
        type: "Tag"
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
  }
);

// convert response to chart.js format
const chartData = computed(() => {
  const photoData = result.value?.photoImpressionCountsByDate;
  const albumData = result.value?.albumImpressionCountsByDate;
  const tagData = result.value?.tagImpressionCountsByDate;

  if (!photoData) return;

  const labels = photoData.map((d) => d.date);
  const photoValues = photoData.map((d) => d.count);
  const albumValues = albumData.map((d) => d.count);
  const tagValues = tagData.map((d) => d.count);

  return {
    labels,
    datasets: [
      {
        label: "Photo Views",
        backgroundColor: "#f87979",
        data: photoValues,
      },
      {
        label: "Album Views",
        backgroundColor: "#7f7fff",
        data: albumValues,
      },
      {
        label: "Tag Views",
        backgroundColor: "#8cff8c",
        data: tagValues,
      },
    ],
  };
});
</script>
