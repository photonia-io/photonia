function getPageTitle (vm) {
  const { pageTitle } = vm.$options
  if (pageTitle) {
    return typeof pageTitle === 'function'
      ? pageTitle.call(vm)
      : pageTitle
  }
}

export default {
  created () {
    this.setPageTitle()
  },
  methods: {
    setPageTitle () {
      const pageTitle = getPageTitle(this)
      if (pageTitle) {
        document.title = pageTitle
      }
    }
  }
}
