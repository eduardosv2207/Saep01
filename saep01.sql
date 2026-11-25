CREATE TABLE colaboradores (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    senha VARCHAR(50) NOT NULL,
    ativo BOOLEAN DEFAULT TRUE
);

--------------------------------------------------------

CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(50) UNIQUE NOT NULL
);

----------------------------------------------------------

CREATE TABLE projetos (
    id SERIAL PRIMARY KEY,
    nome VARCHAR(100) NOT NULL,
    status VARCHAR(20) DEFAULT 'Ativo' CHECK (status IN ('Ativo', 'Concluido', 'Cancelado'))
);

----------------------------------------------------------

CREATE TABLE tarefas (
    id SERIAL PRIMARY KEY,
    colaborador_id INT REFERENCES colaboradores(id) NOT NULL,
    categoria_id INT REFERENCES categorias(id)NOT NULL,
    projeto_id INT REFERENCES projetos(id) NOT NULL,
    titulo VARCHAR(100) NOT NULL,
    data_criacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    prazo_entrega DATE, 
    status VARCHAR(20) DEFAULT 'Pendente' CHECK (status IN ('Pendente','Em Andamento','Concluida'))
);

----------------------------------------------------------

CREATE TABLE historico_tarefas (
    id SERIAL PRIMARY KEY,
    tarefa_id INT REFERENCES tarefas(id),
    acao VARCHAR(100) NOT NULL,
    data_acao TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


----------------------------------------------------------
-- Willer estou com um dificuldade da Triggers, eu pedi pra IA me ajudar, daí eu peguei um pouco na IA,
-- Mas eu pedi pro Bruno me ajudar aqui, daí entendi um pouco

CREATE OR REPLACE FUNCTION fn_validar_tarefa()
RETURNS TRIGGER AS $$

DECLARE
    colaborador_ativo BOOLEAN;
BEGIN
    SELECT ativo
    INTO colaborador_ativo
    FROM colaboradores
    WHERE id = NEW.colaborador_id;

    IF NOT FOUND THEN

        RAISE EXCEPTION
        'Colaborador nao encontrado';
    END IF;

    IF colaborador_ativo = FALSE THEN

        RAISE EXCEPTION
        'Colaborador esta inativo';
    END IF;
    NEW.data_criacao := CURRENT_TIMESTAMP;


RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_validar_tarefa

BEFORE INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_validar_tarefa();

----------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_criar_historico()
RETURNS TRIGGER AS $$

BEGIN
INSERT INTO historico_tarefas
    (tarefa_id, acao)

    VALUES
    (NEW.id, 'Tarefa criada');

RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER trg_criar_historico

AFTER INSERT ON tarefas
FOR EACH ROW
EXECUTE FUNCTION fn_criar_historico();


----------------------------------------------------------

INSERT INTO colaboradores (nome, email, senha, ativo) VALUES
('Eduardo', 'eduardo@email.com', '123', TRUE),
('Ravi', 'ravi@email.com', '456', TRUE),
('Bruno', 'bruno@email.com', '789', FALSE)

----------------------------------------------------------

INSERT INTO categorias (nome) VALUES
('Programacao'),
('Design'),
('Banco de Dados')

----------------------------------------------------------

INSERT INTO projetos (nome, status) VALUES
('Sistema Web', 'Ativo'),
('Aplicativo', 'Ativo'),
('Site da Empresa', 'Ativo')

----------------------------------------------------------


INSERT INTO tarefas (colaborador_id, categoria_id, projeto_id, titulo, prazo_entrega, status) VALUES
(1, 1, 1, 'Criar banco de dados', '2026-11-20', 'Em Andamento'),
(2, 2, 1, 'Criar layout', '2026-11-25', 'Pendente'),
(1, 3, 2, 'Reuniao', '2026-11-30', 'Pendente')

----------------------------------------------------------

CREATE VIEW vw_painel_principal AS SELECT
    c.nome AS colaboradores,
    t.titulo AS tarefa,
    c.nome AS categoria,
    t.prazo_entrega,
    t.status

FROM tarefas t
JOIN colaboradores c
ON tarefas.colaborador_id = colaboradores.id

JOIN categorias c
ON tarefas.categoria_id = categorias.id


----------------------------------------------------------
-- Willer como eu não entendi muito bem essas partes eu pedi para IA me ajudar explicando cada parte
-- daí, eu usei mas entendi a lógica
CREATE OR REPLACE FUNCTION fn_buscar_colaboradores(
    termo TEXT
)

RETURNS TABLE (
    nome_colaborador VARCHAR,
    email_colaborador VARCHAR
)

AS $$

BEGIN
    RETURN QUERY
    SELECT
        colaboradores.nome,
        colaboradores.email
    FROM colaboradores

WHERE colaboradores.nome
        ILIKE '%' || termo || '%'
OR colaboradores.email
        ILIKE '%' || termo || '%';
END;

$$ LANGUAGE plpgsql;

----------------------------------------------------------

CREATE VIEW vw_cronograma_prazos AS SELECT
    t.titulo AS tarefa,
    t.status,
    t.prazo_entrega,
    t.prazo_entrega - CURRENT_DATE AS dias_restantes,
    c.nome AS responsavel

FROM tarefas t
JOIN colaboradores c
ON tarefas.colaborador_id = colaboradores.id
ORDER BY asc tarefas.prazo_entrega 