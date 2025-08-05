
import util/common_utils
import gleam/javascript/promise

pub type FetchOrStoreError(fetch_data, fetch_error, store_error)
{
    FetchError(fetch_error)
    StoreError(fetch_data, store_error)
}

pub fn get_or_fetch_and_store(
    get, fetch, store
)
{
    use data <- common_utils.async(get)
    case data
    {
        Ok(data) -> promise.resolve(Ok(data))
        Error(_) -> {
            use data <- promise.await(fetch())
            case data
            {
                Error(error) -> Error(FetchError(error))
                Ok(data) -> case store(data)
                {
                    Ok(_) -> Ok(data)
                    Error(error) -> Error(StoreError(data, error))
                }
            } |> promise.resolve()
        }
    }
}