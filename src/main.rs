use actix_web::{post, HttpResponse, Responder, App, HttpServer};
use rand::Rng;
use embryo::{Embryo, EmbryoList};
use std::collections::HashMap;

#[post("/query")]
async fn query_handler(body: String) -> impl Responder {
    let embryo_list = generate_embryo_list(body);
    let response = EmbryoList { embryo_list };
    HttpResponse::Ok().json(response)
}

fn generate_embryo_list(json_string: String) -> Vec<Embryo> {
    println!("Call {}", json_string);
    let em_search: HashMap<String,String> = serde_json::from_str(&json_string).expect("Error deserializing JSON");
    let (_key, value) = em_search.iter().next().expect("Empty map");   
    let mut rng = rand::thread_rng();
    let mut embryo_list = Vec::new();

    for _ in 0..10 {
        let random_number: u32 = rng.gen_range(1..=100);
        let random_number_str = random_number.to_string();

        if random_number_str.contains(value) || value.contains(&random_number_str) {
            let mut embryo_properties = HashMap::new();
            embryo_properties.insert("url".to_string(),format!("http://example/{}", random_number));
            embryo_properties.insert("resume".to_string(),random_number_str);
            let embryo = Embryo {
                properties: embryo_properties,
            };
            embryo_list.push(embryo);
        }
    }

    embryo_list
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    match em_filter::find_port().await {
        Some(port) => {
            let filter_url = format!("http://localhost:{}/query", port);
            println!("Filter registrer: {}", filter_url);
            em_filter::register_filter(&filter_url).await;
            HttpServer::new(|| App::new().service(query_handler))
                .bind(format!("127.0.0.1:{}", port))?.run().await?;
        },
        None => {
            println!("Can't start");
        },
    }
    Ok(())
}

