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
  expect(wrapper.findAllComponents(RouterLinkStub).length).toBe(8)
  // expect(wrapper.findAllComponents(RouterLinkStub)[0].classes()).toContain("disabled")

  // check if the previous button leads to page 1
  expect(wrapper.findAllComponents(RouterLinkStub)[0].props().to).toEqual({ name: "photos-index" })

  // check if the next button leads to page 3
  expect(wrapper.findAllComponents(RouterLinkStub)[1].props().to).toEqual({ name: "photos-index", query: { page: 3 } })

  // check if the first page in the list is 1
  expect(wrapper.findAllComponents(RouterLinkStub)[2].props().to).toEqual({ name: "photos-index" })

  // check if the last page in the list is 10
  expect(wrapper.findAllComponents(RouterLinkStub)[7].props().to).toEqual({ name: "photos-index", query: { page: 10 } })

  // console.log(wrapper.findAllComponents(RouterLinkStub)[0].classes())
  // console.log(wrapper.findAllComponents(RouterLinkStub)[0].props())
  // console.log(wrapper.findAll("nav.pagination > *")[2].classes())
})
