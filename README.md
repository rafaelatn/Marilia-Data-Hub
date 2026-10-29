# Marília DataHub

Plataforma municipal de administração e qualidade de dados, desenvolvida na disciplina **Fábrica de Projetos Ágeis II** (2º semestre de Inteligência Artificial, UNIMAR – Marília), em parceria com a **STI – Secretaria de Tecnologia e Inovação de Marília**.

## Problema

Os dados das secretarias municipais não eram padronizados e o tratamento era manual, o que gerava desorganização e atrasos no compartilhamento das informações com a população.

## Solução

O Marília DataHub integrou e padronizou os dados das secretarias, avaliou sua qualidade com apoio de IA e os disponibilizou em um painel de gestão e em um portal de dados abertos.

## Objetivos

- Automatizar a ingestão, a padronização e a verificação de qualidade dos dados.
- Atribuir um **Data Quality Score** a cada versão de dataset.
- Consolidar o histórico de registros dispersos entre as secretarias.
- Reduzir o trabalho manual e os erros de tratamento.
- Disponibilizar indicadores e mapeamento administrativo à população.

## Arquitetura

| Frente | Implementação |
|---|---|
| **Banco de dados** | PostgreSQL, modelado no pgAdmin; dados sintéticos gerados com Python + openpyxl e validados com pandas |
| **Mineração de dados** | Python (Pandas e NumPy): correção de inconsistências, padronização e registro das alterações no **Data Passport** |
| **Controle de qualidade por IA** | Great Expectations (métricas do score), RapidFuzz (fuzzy matching) e sentence-transformers (embeddings semânticos) para sugerir padronizações; scores versionados no PostgreSQL e expostos no catálogo de metadados (OpenMetadata ou DataHub) |
| **Backend** | Python + FastAPI; autenticação e autorização com Keycloak, OAuth2 e JWT; Row-Level Security (RLS) do PostgreSQL |
| **Frontend** | React; telas adaptadas ao perfil do usuário (STI vê todas as secretarias; cada secretaria vê apenas seus dados) |
| **Dados abertos** | CKAN; somente datasets que atingiram o score mínimo foram publicados, por ação do responsável |

### Fluxo geral

```
Secretarias → Banco de Dados → Mineração → Controle de Qualidade por IA → Backend → Frontend → Sociedade / Gestão Pública
                                   ↑______________ feedback (sugestões) ______________|
```

## Resultados

- Cinco frentes definidas, com ferramentas e responsabilidades divididas entre os integrantes.
- Modelo relacional de **7 tabelas** (secretarias, unidades, bairros, catálogo de datasets, dicionário de dados e Data Passport com histórico de versões).
- Script de criação em PostgreSQL testado e validado com uma planilha de **5 datasets sintéticos**.
- Protótipo interativo do painel de gestão pública.

## Equipe

- Danilo Queiroz Luiz
- Kelvin Rodrigues dos Santos
- Larah Cezário Lima da Silva
- Lucas Nakamura Dias Moraes
- Rafaela Tavares Návia

## Referências

- ALMEIDA, A. T. S. B. de et al. *O impacto da Indústria 4.0 na qualidade e como as tecnologias habilitadoras beneficiam a operação*. SIMEA 2024, São Paulo.
- MARÍLIA (Município). Secretaria Municipal de Tecnologia da Informação. [Política de backup](https://www.marilia.sp.gov.br/arquivos/politica_de_backup_22030659.pdf).
- SCIPOPULIS. [Plancity](https://scipopulis.com/plancity).
