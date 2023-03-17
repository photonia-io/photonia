import Pagination from "@/shared/pagination.vue";
import { mount, RouterLinkStub } from "@vue/test-utils";

test("Pagination renders the correct elements", () => {
  expect(Pagination).toBeTruthy();
  const wrapper = mount(Pagination, {
    props: {
      metadata: {
        currentPage: 2,
        totalPages: 10
      },
      routeName: "photos-index"
    },
    global: {
      stubs: {
        RouterLink: RouterLinkStub
      }  
    } 
  })
  expect(wrapper.find("nav.pagination").exists()).toBe(true)
  expect(wrapper.findAllComponents(RouterLinkStub).length).toBe(6)
  // console.log(wrapper.findAllComponents(RouterLinkStub)[0].classes())
  // console.log(wrapper.findAll("nav.pagination > *")[2].classes())
})