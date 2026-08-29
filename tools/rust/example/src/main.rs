use actix_web::{web, App, HttpServer, HttpResponse};
use serde::Serialize;
use std::env;

#[derive(Serialize)]
struct Health { status: String, tool: String, language: String }

#[derive(Serialize)]
struct Echo { input: serde_json::Value, language: String }

async fn health() -> HttpResponse {
    HttpResponse::Ok().json(Health {
        status: "ok".into(),
        tool: env::var("TOOL_NAME").unwrap_or("rust-tool".into()),
        language: "rust".into(),
    })
}

async fn index() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({
        "message": "Rust Tool läuft!",
        "tool": env::var("TOOL_NAME").unwrap_or("rust-tool".into())
    }))
}

async fn echo(data: web::Json<serde_json::Value>) -> HttpResponse {
    HttpResponse::Ok().json(Echo { input: data.into_inner(), language: "rust".into() })
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    env_logger::init();
    let port = env::var("PORT").unwrap_or("8080".into()).parse().unwrap();
    println!("Rust tool starting on port {}", port);
    
    HttpServer::new(|| App::new()
        .route("/health", web::get().to(health))
        .route("/", web::get().to(index))
        .route("/api/echo", web::post().to(echo))
    )
    .bind(("0.0.0.0", port))?
    .run()
    .await
}