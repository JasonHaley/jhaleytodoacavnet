export interface ApiConfig {
    baseUrl: string
}

export interface ObservabilityConfig {
    instrumentationKey: string
}

export interface AppConfig {
    api: ApiConfig
    observability: ObservabilityConfig
}

const config: AppConfig = {
    api: {
        baseUrl: '/v1' || 'https://localhost:7025/v1'
    },
    observability: {
        instrumentationKey: ''
    }
}

export default config;