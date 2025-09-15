import model/dolibarr/constant/country_model
import service/dolibarr_service
import util/token.{type Token}

pub fn fetch_all(token: Token)
{
    token |> dolibarr_service.fetch_all(
        at: ["setup", "dictionary", "countries"],
        expect: country_model.decoder(),
        take: 1000,
        page: 1,
        where: []
    )
}