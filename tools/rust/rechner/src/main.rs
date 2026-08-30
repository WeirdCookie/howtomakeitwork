use actix_web::{web, App, HttpServer, HttpResponse};
use std::env;

async fn health() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({
        "status": "ok",
        "tool": "rechner",
        "language": "rust"
    }))
}

async fn index() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({
        "tool": "rechner",
        "message": "Rust Rechner läuft!",
        "endpoints": ["/api/rechner/add?a=1&b=2"]
    }))
}

async fn add(query: web::Query<std::collections::HashMap<String, i64>>) -> HttpResponse {
    let a = query.get("a").copied().unwrap_or(0);
    let b = query.get("b").copied().unwrap_or(0);
    HttpResponse::Ok().json(serde_json::json!({
        "a": a,
        "b": b,
        "sum": a + b,
        "language": "rust"
    }))
}

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    let port: u16 = env::var("PORT").unwrap_or_else(|_| "8080".into()).parse().unwrap();
    println!("rechner startet auf Port {}", port);
    HttpServer::new(|| {
        App::new()
            .route("/health", web::get().to(health))
            .route("/", web::get().to(index))
            .route("/api/rechner/add", web::get().to(add))
    })
    .bind(("0.0.0.0", port))?
    .run()
    .await
}
