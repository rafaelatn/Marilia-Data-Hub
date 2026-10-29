DROP TABLE IF EXISTS dataset_relacao, dataset_versao, dicionario_coluna,
  dataset, unidade, bairro, secretaria CASCADE;
DROP TYPE IF EXISTS formato_dataset, periodicidade_dataset,
  classificacao_dataset, tipo_dado_coluna CASCADE;
 
CREATE TABLE secretaria (
  id_secretaria      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome               VARCHAR(100) NOT NULL UNIQUE,
  sigla              VARCHAR(10)  NOT NULL UNIQUE,
  responsavel        VARCHAR(100),
  email_contato      VARCHAR(100)
);
 
CREATE TABLE bairro (
  id_bairro          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome               VARCHAR(100) NOT NULL UNIQUE
);
 
CREATE TABLE unidade (
  id_unidade         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome               VARCHAR(100) NOT NULL,
  tipo               VARCHAR(50)  NOT NULL,
  endereco           VARCHAR(150),
  id_secretaria      INTEGER NOT NULL REFERENCES secretaria (id_secretaria),
  id_bairro          INTEGER REFERENCES bairro (id_bairro),
  UNIQUE (nome, id_bairro)
);
 
CREATE TYPE formato_dataset AS ENUM ('csv','xlsx','json','pdf','banco_de_dados','outro');
CREATE TYPE periodicidade_dataset AS ENUM ('diaria','semanal','mensal','trimestral','anual','eventual');
CREATE TYPE classificacao_dataset AS ENUM ('publico','restrito','sigiloso');
 
CREATE TABLE dataset (
  id_dataset         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  nome               VARCHAR(150) NOT NULL,
  descricao          TEXT,
  id_secretaria      INTEGER NOT NULL REFERENCES secretaria (id_secretaria),
  formato            formato_dataset       NOT NULL DEFAULT 'csv',
  periodicidade      periodicidade_dataset NOT NULL DEFAULT 'mensal',
  classificacao      classificacao_dataset NOT NULL DEFAULT 'publico',
  contem_dados_pessoais BOOLEAN NOT NULL DEFAULT FALSE,
  data_cadastro      TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (id_secretaria, nome)
);
 
CREATE TYPE tipo_dado_coluna AS ENUM ('texto','inteiro','decimal','data','data_hora','booleano');
 
CREATE TABLE dicionario_coluna (
  id_coluna          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_dataset         INTEGER NOT NULL REFERENCES dataset (id_dataset) ON DELETE CASCADE,
  nome_coluna        VARCHAR(100) NOT NULL,
  tipo_dado          tipo_dado_coluna NOT NULL DEFAULT 'texto',
  descricao          VARCHAR(255),
  obrigatoria        BOOLEAN NOT NULL DEFAULT FALSE,
  exemplo            VARCHAR(100),
  UNIQUE (id_dataset, nome_coluna)
);
 
CREATE TABLE dataset_versao (
  id_versao          INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_dataset         INTEGER NOT NULL REFERENCES dataset (id_dataset),
  numero_versao      INTEGER NOT NULL,
  data_referencia    DATE,
  data_envio         TIMESTAMP NOT NULL DEFAULT now(),
  arquivo_original   VARCHAR(255) NOT NULL,
  hash_arquivo       CHAR(64),
  enviado_por        VARCHAR(100) NOT NULL,
  observacoes        TEXT,
  UNIQUE (id_dataset, numero_versao)
);
 
CREATE TABLE dataset_relacao (
  id_relacao         INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  id_dataset_origem  INTEGER NOT NULL REFERENCES dataset (id_dataset) ON DELETE CASCADE,
  id_dataset_destino INTEGER NOT NULL REFERENCES dataset (id_dataset) ON DELETE CASCADE,
  campo_em_comum     VARCHAR(100) NOT NULL,
  descricao          VARCHAR(255),
  UNIQUE (id_dataset_origem, id_dataset_destino, campo_em_comum),
  CHECK (id_dataset_origem <> id_dataset_destino)
);
 
ALTER TABLE dataset ENABLE ROW LEVEL SECURITY;
 
CREATE POLICY dataset_visivel ON dataset
  FOR SELECT
  USING (
    classificacao = 'publico'
    OR id_secretaria = current_setting('app.secretaria_atual', true)::INTEGER
  );
 
CREATE POLICY dataset_edita_proprio ON dataset
  FOR ALL
  USING (id_secretaria = current_setting('app.secretaria_atual', true)::INTEGER)
  WITH CHECK (id_secretaria = current_setting('app.secretaria_atual', true)::INTEGER);
 
INSERT INTO secretaria (nome, sigla, responsavel, email_contato) VALUES
 ('Secretaria de Tecnologia e Inovação', 'SETI', 'Responsável Exemplo 1', 'seti@exemplo.gov.br'),
 ('Secretaria de Saúde',                 'SMS',  'Responsável Exemplo 2', 'saude@exemplo.gov.br'),
 ('Secretaria de Educação',              'SME',  'Responsável Exemplo 3', 'educacao@exemplo.gov.br'),
 ('Secretaria de Assistência Social',    'SAS',  'Responsável Exemplo 4', 'social@exemplo.gov.br');
 
INSERT INTO bairro (nome) VALUES
 ('Centro'), ('Fragata'), ('Palmital'), ('Cascata');
 
INSERT INTO unidade (nome, tipo, endereco, id_secretaria, id_bairro) VALUES
 ('UBS Exemplo Centro',        'UBS',    'Rua Exemplo, 100',   2, 1),
 ('UBS Exemplo Fragata',       'UBS',    'Av. Exemplo, 200',   2, 2),
 ('UBS Exemplo Palmital',      'UBS',    'Rua Exemplo, 300',   2, 3),
 ('UBS Exemplo Cascata',       'UBS',    'Rua Exemplo, 400',   2, 4),
 ('Escola Exemplo Centro',     'Escola', 'Rua Modelo, 110',    3, 1),
 ('Escola Exemplo Centro II',  'Escola', 'Rua Modelo, 120',    3, 1),
 ('Escola Exemplo Fragata',    'Escola', 'Av. Modelo, 210',    3, 2),
 ('Escola Exemplo Fragata II', 'Escola', 'Av. Modelo, 220',    3, 2),
 ('Escola Exemplo Palmital',   'Escola', 'Rua Modelo, 310',    3, 3),
 ('Escola Exemplo Palmital II','Escola', 'Rua Modelo, 320',    3, 3),
 ('Escola Exemplo Cascata',    'Escola', 'Rua Modelo, 410',    3, 4),
 ('Escola Exemplo Cascata II', 'Escola', 'Rua Modelo, 420',    3, 4),
 ('CRAS Exemplo Centro',       'CRAS',   'Rua Teste, 130',     4, 1),
 ('CRAS Exemplo Fragata',      'CRAS',   'Av. Teste, 230',     4, 2),
 ('CRAS Exemplo Palmital',     'CRAS',   'Rua Teste, 330',     4, 3),
 ('CRAS Exemplo Cascata',      'CRAS',   'Rua Teste, 430',     4, 4);
 
INSERT INTO dataset
 (nome, descricao, id_secretaria, formato, periodicidade, classificacao, contem_dados_pessoais) VALUES
 ('Atendimentos nas UBS', 'Atendimentos por UBS, bairro e tipo (consulta médica, enfermagem, odontológico)', 2, 'xlsx', 'mensal', 'restrito', FALSE),
 ('Vacinação nas UBS',    'Doses aplicadas x meta por UBS e vacina',                                          2, 'xlsx', 'mensal', 'publico',  FALSE),
 ('Matrículas por Escola','Matrículas e turmas por escola, bairro e etapa de ensino',                         3, 'csv',  'anual',  'publico',  FALSE),
 ('Famílias Cadastradas', 'Totais de famílias no CadÚnico e em acompanhamento por CRAS (sem dados pessoais)', 4, 'csv',  'mensal', 'sigiloso', TRUE),
 ('Chamados de Suporte de TI', 'Chamados de suporte de TI abertos por cada secretaria',                       1, 'xlsx', 'mensal', 'restrito', FALSE);
 
INSERT INTO dicionario_coluna (id_dataset, nome_coluna, tipo_dado, descricao, obrigatoria, exemplo) VALUES
 (1,'data_referencia','data','Primeiro dia do mês a que o dado se refere',TRUE,'2026-07-01'),
 (1,'unidade','texto','Nome da UBS',TRUE,'UBS Exemplo Centro'),
 (1,'bairro','texto','Bairro da unidade',TRUE,'Centro'),
 (1,'tipo_atendimento','texto','Consulta médica, Enfermagem ou Odontológico',TRUE,'Enfermagem'),
 (1,'qtd_atendimentos','inteiro','Atendimentos realizados no mês',TRUE,'312'),
 (2,'data_referencia','data','Primeiro dia do mês a que o dado se refere',TRUE,'2026-07-01'),
 (2,'unidade','texto','Nome da UBS',TRUE,'UBS Exemplo Fragata'),
 (2,'bairro','texto','Bairro da unidade',TRUE,'Fragata'),
 (2,'vacina','texto','Vacina aplicada',TRUE,'Influenza'),
 (2,'doses_aplicadas','inteiro','Doses aplicadas no mês',TRUE,'118'),
 (2,'meta_doses','inteiro','Meta de doses do mês para a unidade',TRUE,'195'),
 (3,'ano_letivo','inteiro','Ano letivo das matrículas',TRUE,'2026'),
 (3,'escola','texto','Nome da escola',TRUE,'Escola Exemplo Palmital'),
 (3,'bairro','texto','Bairro da escola',TRUE,'Palmital'),
 (3,'etapa','texto','Educação Infantil, Fundamental I ou Fundamental II',TRUE,'Fundamental I'),
 (3,'qtd_matriculas','inteiro','Alunos matriculados na etapa',TRUE,'176'),
 (3,'qtd_turmas','inteiro','Turmas abertas na etapa',FALSE,'7'),
 (4,'data_referencia','data','Primeiro dia do mês a que o dado se refere',TRUE,'2026-03-01'),
 (4,'cras','texto','Nome do CRAS',TRUE,'CRAS Exemplo Cascata'),
 (4,'bairro','texto','Bairro do CRAS',TRUE,'Cascata'),
 (4,'familias_cadunico','inteiro','Total de famílias no Cadastro Único',TRUE,'325'),
 (4,'familias_em_acompanhamento','inteiro','Famílias em acompanhamento no mês',FALSE,'70'),
 (4,'atendimentos_realizados','inteiro','Atendimentos realizados no mês',TRUE,'112'),
 (5,'data_referencia','data','Primeiro dia do mês a que o dado se refere',TRUE,'2026-07-01'),
 (5,'secretaria','texto','Sigla da secretaria que abriu o chamado',TRUE,'SMS'),
 (5,'tipo_chamado','texto','Hardware, Rede ou Sistema',TRUE,'Rede'),
 (5,'qtd_chamados','inteiro','Chamados abertos no mês',TRUE,'14'),
 (5,'tempo_medio_horas','decimal','Tempo médio de resolução em horas',FALSE,'6.5');
 
INSERT INTO dataset_versao (id_dataset, numero_versao, data_referencia, arquivo_original, enviado_por, observacoes) VALUES
 (1, 1, '2026-07-01', 'raw/saude/atendimentos_ubs_2026_07.xlsx', 'Servidor Exemplo SMS', 'Carga de julho'),
 (1, 2, '2026-08-01', 'raw/saude/atendimentos_ubs_2026_08.xlsx', 'Servidor Exemplo SMS', 'Carga de agosto'),
 (2, 1, '2026-07-01', 'raw/saude/vacinacao_ubs_2026_07.xlsx',    'Servidor Exemplo SMS', 'Carga de julho'),
 (2, 2, '2026-08-01', 'raw/saude/vacinacao_ubs_2026_08.xlsx',    'Servidor Exemplo SMS', 'Carga de agosto'),
 (3, 1, '2026-01-01', 'raw/educacao/matriculas_2026.csv',        'Servidor Exemplo SME', 'Matrículas do ano letivo 2026'),
 (4, 1, '2026-03-01', 'raw/social/familias_cras_2026_03.csv',    'Servidor Exemplo SAS', 'Carga de março'),
 (4, 2, '2026-04-01', 'raw/social/familias_cras_2026_04.csv',    'Servidor Exemplo SAS', 'Carga de abril'),
 (4, 3, '2026-05-01', 'raw/social/familias_cras_2026_05.csv',    'Servidor Exemplo SAS', 'Carga de maio'),
 (4, 4, '2026-06-01', 'raw/social/familias_cras_2026_06.csv',    'Servidor Exemplo SAS', 'Carga de junho'),
 (4, 5, '2026-07-01', 'raw/social/familias_cras_2026_07.csv',    'Servidor Exemplo SAS', 'Carga de julho'),
 (4, 6, '2026-08-01', 'raw/social/familias_cras_2026_08.csv',    'Servidor Exemplo SAS', 'Carga de agosto'),
 (5, 1, '2026-07-01', 'raw/seti/chamados_ti_2026_07.xlsx',       'Servidor Exemplo SETI', 'Carga de julho'),
 (5, 2, '2026-08-01', 'raw/seti/chamados_ti_2026_08.xlsx',       'Servidor Exemplo SETI', 'Carga de agosto');
 
INSERT INTO dataset_relacao (id_dataset_origem, id_dataset_destino, campo_em_comum, descricao) VALUES
 (1, 2, 'unidade',    'Cruzar atendimentos e vacinação na mesma UBS'),
 (1, 3, 'bairro',     'Cruzar demanda de saúde com oferta de vagas escolares por bairro'),
 (1, 4, 'bairro',     'Cruzar atendimentos de saúde com famílias no CadÚnico por bairro'),
 (2, 4, 'bairro',     'Cruzar cobertura vacinal com famílias em acompanhamento por bairro'),
 (3, 4, 'bairro',     'Cruzar matrículas com famílias atendidas nos CRAS por bairro'),
 (5, 1, 'secretaria', 'Comparar chamados de TI com o volume de atendimentos da Saúde'),
 (5, 3, 'secretaria', 'Comparar chamados de TI com a estrutura da Educação'),
 (5, 4, 'secretaria', 'Comparar chamados de TI com a estrutura da Assistência Social');
 
SELECT d.nome AS dataset, s.sigla AS secretaria, d.formato, d.periodicidade, d.classificacao
FROM dataset d JOIN secretaria s ON s.id_secretaria = d.id_secretaria
ORDER BY s.sigla, d.nome;
 
SELECT d.nome AS dataset, v.numero_versao, v.data_referencia, v.data_envio, v.enviado_por, v.arquivo_original
FROM dataset_versao v JOIN dataset d ON d.id_dataset = v.id_dataset
WHERE d.id_dataset = 4
ORDER BY v.numero_versao;
 
SELECT o.nome AS dataset_origem, so.sigla AS sec_origem, r.campo_em_comum,
       dd.nome AS dataset_destino, sd.sigla AS sec_destino
FROM dataset_relacao r
JOIN dataset o     ON o.id_dataset     = r.id_dataset_origem
JOIN secretaria so ON so.id_secretaria = o.id_secretaria
JOIN dataset dd    ON dd.id_dataset    = r.id_dataset_destino
JOIN secretaria sd ON sd.id_secretaria = dd.id_secretaria
ORDER BY r.campo_em_comum, o.nome;
 
SELECT d.nome, s.sigla, d.classificacao
FROM dataset d JOIN secretaria s ON s.id_secretaria = d.id_secretaria
WHERE d.contem_dados_pessoais = TRUE;