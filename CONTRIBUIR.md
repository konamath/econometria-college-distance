# Como trabalhar em grupo

O repositório contém a primeira etapa do trabalho: análise descritiva da CollegeDistance. A versão principal fica na branch `main`. Cada alteração deve ter um objetivo claro e ser revisada por outro integrante antes de entrar nessa versão.

## Começar no seu computador

1. No GitHub, use **Code > Open with GitHub Desktop** e escolha onde salvar o projeto. Se preferir o VS Code, use **Git: Clone** e cole o endereço do repositório.
2. Abra a pasta clonada no VS Code ou no RStudio.
3. Instale o R, caso ainda não esteja disponível, e execute `00_preparar_ambiente.R` uma vez.
4. Execute `01_descritiva.R` e confira se a análise termina sem erros. O README explica os modos de execução.

Baixar o ZIP permite consultar e executar os arquivos, mas não conecta a pasta ao histórico do Git. Para colaborar, prefira clonar o repositório.

## Fazer uma alteração

1. Atualize sua cópia da `main` com **Fetch origin** e **Pull origin** no GitHub Desktop.
2. Crie uma branch com um nome descritivo, como `melhorar-grafico-renda`.
3. Edite os scripts ou a documentação. Combine com o grupo antes de mudar o escopo da análise.
4. Execute a análise completa em uma sessão limpa. No terminal, dentro da pasta do projeto:

```sh
Rscript --vanilla 01_descritiva.R
```

5. Confira as alterações no GitHub Desktop ou na seção **Source Control** do VS Code. Inclua os arquivos necessários e faça um commit com uma descrição objetiva.
6. Publique a branch e abra um **pull request**, que é um pedido para incorporar a alteração à versão principal.
7. Peça a outro integrante para conferir o código e os resultados. Após a revisão, incorpore a mudança à `main` e atualize as cópias locais.

## Dados e resultados

- Não edite manualmente os CSVs, gráficos ou a nota gerada. Altere o script e execute novamente.
- Quando a mudança alterar resultados, inclua na mesma proposta o código e os resultados correspondentes. O autor da proposta fica responsável por gerá-los.
- Se a alteração for apenas de documentação, não inclua diferenças de gráficos ou do `sessionInfo.txt` causadas por uma execução local sem relação com a mudança.
- Não apague o trabalho de outra pessoa para resolver um conflito. Comparem as duas alterações e preservem o que fizer sentido.
- A base é pública e vem do pacote AER. Não adicionem arquivos pessoais, senhas ou dados privados ao repositório público.
- As versões testadas estão em `resultados/sessionInfo.txt`. A instalação não fixa automaticamente todas as versões. Se um resultado divergir, comparem a versão do AER, do R e dos demais pacotes antes de alterar a análise.

## Descrever a proposta

No pull request, expliquem em poucas frases:

- O que mudou e por quê.
- Como verificaram que o script funciona.
- Quais tabelas, gráficos ou interpretações foram afetados.

Uma melhoria por proposta facilita a revisão. Não alterem controles ou excluam observações apenas para obter significância estatística.

## Acesso

Qualquer pessoa pode visualizar e baixar o repositório público. Para publicar branches diretamente nele, cada integrante precisa aceitar um convite como colaborador. Quem ainda não tiver esse acesso pode criar um fork e propor mudanças por pull request.

Referências: [convites a colaboradores](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/repository-access-and-collaboration/inviting-collaborators-to-a-personal-repository) e [GitHub flow](https://docs.github.com/en/get-started/using-github/github-flow).
