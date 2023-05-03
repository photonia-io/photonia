import { useApplicationStore } from "../stores/application";
import { useQuery } from '@vue/apollo-composable'

const useQueryWithFetchPolicy = (query, params) => {
  const applicationStore = useApplicationStore()

  const fetchPolicy = applicationStore.photoListChanged ? 'cache-and-network' : 'cache-first'
  return useQuery(query, params, { fetchPolicy: fetchPolicy })
}

export default useQueryWithFetchPolicy
