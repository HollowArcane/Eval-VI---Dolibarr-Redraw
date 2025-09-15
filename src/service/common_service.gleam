
import gleam/function
import gleam/list
import util/common_utils
import gleam/javascript/promise

pub type FetchOrStoreError(fetch_data, fetch_error, store_error)
{
    FetchError(fetch_error)
    StoreError(fetch_data, store_error)
}


pub fn sequential_batch_fold(data, initial_value, action)
{
	use acc, row <- list.fold(data, promise.resolve(Ok(initial_value)))
	use acc <- promise.try_await(acc)
	use value <- promise.try_await(action(acc, row))
	promise.resolve(Ok(value))
}

pub fn sequential_batch(data, action)
{
	use acc, row <- list.fold(data, promise.resolve(Ok([])))
	use acc <- promise.try_await(acc)
	use value <- promise.try_await(action(row))
	promise.resolve(Ok([value, ..acc]))
}

pub fn batch(data, action)
{
    use products <- promise.map(promise.await_list(
        list.map(data, action)
    ))
    list.try_map(products, function.identity)
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
