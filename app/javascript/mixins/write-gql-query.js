const writeGQLQuery = (queryString, GQLQuery) => ({
  beforeCreate: function() {
    if(typeof gql_cached_query !== 'undefined' && queryString == gql_cached_query) {
      this.$apollo.provider.defaultClient.writeQuery({
        query: GQLQuery,
        data: gql_cached_result.data
      });
    }
  }
})

export default writeGQLQuery
