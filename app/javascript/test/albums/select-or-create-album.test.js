import { describe, it, expect, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { ref } from "vue";

const queryState = vi.hoisted(() => ({ result: null, variables: null }));

vi.mock("@vue/apollo-composable", () => ({
  useQuery: vi.fn((_document, variables) => {
    queryState.variables = variables;
    return { result: queryState.result };
  }),
}));

import SelectOrCreateAlbum from "../../albums/select-or-create-album.vue";

// The exact shape the real CurrentUserAlbumsQuery returns for photo
// 80769840532, which sits in three of the seven albums.
const payload = {
  currentUser: {
    albums: [
      { id: "72157636194982077", title: "A Ridiculously Long Album Title", photosCount: 7 },
      { id: "72157636187887063", title: "Test Album (two albums per photo)", photosCount: 7 },
      { id: "72157636185931555", title: "Fredy", photosCount: 16 },
      { id: "72157607411295448", title: "September snow", photosCount: 16 },
      { id: "72157600407568654", title: "My Cats", photosCount: 25 },
    ],
    albumsWithPhotos: [
      { id: "72157600407568654", containedPhotosCount: 1 },
      { id: "72157636187887063", containedPhotosCount: 1 },
      { id: "72157636194982077", containedPhotosCount: 1 },
    ],
  },
};

function mountSelect(props = {}, result = payload) {
  queryState.result = ref(result);

  return mount(SelectOrCreateAlbum, {
    props: { photos: [{ id: "80769840532" }], ...props },
  });
}

const optionValues = (wrapper) =>
  wrapper
    .findAll("option")
    .map((o) => o.attributes("value"))
    .filter(Boolean);

describe("SelectOrCreateAlbum", () => {
  it("leaves out the albums that already contain every given photo", () => {
    const wrapper = mountSelect();

    expect(optionValues(wrapper)).toEqual([
      "72157636185931555",
      "72157607411295448",
    ]);
  });

  it("keeps an album that holds only some of the given photos", () => {
    const wrapper = mountSelect(
      { photos: [{ id: "a" }, { id: "b" }] },
      {
        currentUser: {
          albums: [
            { id: "partial", title: "Partial", photosCount: 4 },
            { id: "full", title: "Full", photosCount: 9 },
          ],
          albumsWithPhotos: [
            { id: "partial", containedPhotosCount: 1 },
            { id: "full", containedPhotosCount: 2 },
          ],
        },
      },
    );

    expect(optionValues(wrapper)).toEqual(["partial"]);
  });

  it("passes the photo ids to the query", () => {
    mountSelect();
    expect(queryState.variables.photoIds.value).toEqual(["80769840532"]);
  });
});
