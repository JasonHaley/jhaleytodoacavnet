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
        baseUrl: window.ENV_CONFIG.REACT_APP_API_BASE_URL + '/v1' || 'https://localhost:7025/v1'
    },
    observability: {
        instrumentationKey: window.ENV_CONFIG.REACT_APP_APPINSIGHTS_INSTRUMENTATIONKEY || ''
    }
}

export default config;