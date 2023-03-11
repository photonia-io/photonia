import Pagination from "../../app/javascript/pagination.vue";
import { mount } from "@vue/test-utils";

test("Pagination renders the correct elements", () => {
  expect(Pagination).toBeTruthy();
  const wrapper = mount(Pagination, {
    props: {
      metadata: {
        currentPage: 1,
      },
      path: "photos-index"
    },
    global: {
      stubs: {
        "router-link": "<div></div>"
      }  
    }
  })
})