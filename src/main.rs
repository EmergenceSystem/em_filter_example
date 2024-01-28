use actix_web::{post, HttpResponse, Responder, App, HttpServer};
use reqwest;
use rand::Rng;
use serde::{Serialize, Deserialize};
use embryo::{Embryo, EmPair, EmbryoList};

static PORT: i32 = 8081;
static REGISTRY_URL: &str = "http://localhost:8080";

#[derive(Serialize, Deserialize)]
struct FilterInfo {
    url: String,
}

#[post("/query")]
async fn query_handler(body: String) -> impl Responder {
    let embryo_list = generate_embryo_list(body);
    let response = EmbryoList { embryo_list };
    HttpResponse::Ok().json(response)
}

fn generate_embryo_list(json_string: String) -> Vec<Embryo> {
    println!("Call {}", json_string);
    let search: EmPair =
        serde_json::from_str(&json_string).expect("Error deserializing JSON");
    let mut rng = rand::thread_rng();
    let mut embryo_list = Vec::new();

    for _ in 0..10 {
        let random_number: u32 = rng.gen_range(1..=100);
        let random_number_str = random_number.to_string();

        if random_number_str.contains(&search.value) || search.value.contains(&random_number_str) {
            let embryo = Embryo {
                properties: vec![
                    EmPair {
                        name: "url".to_string(),
                        value: format!("http://example.com:{}/{}", PORT, random_number),
                    },
                    EmPair {
                        name: "resume".to_string(),
                        value: random_number_str,
                    },
                ],
            };
            embryo_list.push(embryo);
        }
    }

    embryo_list
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    // Register filter on startup
    let filter_url = format!("http://localhost:{}/query", PORT);
    register_filter(&filter_url).await;
    println!("Filter registered: {}", filter_url);

    // Start Actix web server
    HttpServer::new(|| App::new().service(query_handler))
        .bind(format!("127.0.0.1:{}", PORT))?
        .run()
        .await?;

    Ok(())
}

async fn register_filter(url: &str) {
    let filter_info = FilterInfo { url: url.to_string() };
    let register_url = format!("{}/register", REGISTRY_URL);

    match reqwest::Client::new()
        .post(&register_url)
        .header("Content-Type", "application/json")
        .body(serde_json::to_string(&filter_info).expect("Error serializing JSON"))
        .send()
        .await
        {
            Ok(_) => println!("Filter registered with the central registry."),
            Err(e) => eprintln!("Failed to register filter: {:?}", e),
        }
}

