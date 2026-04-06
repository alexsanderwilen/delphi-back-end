unit Usuario.AlterarSenha.DTO;

interface

Type
  TUsuarioAlterarSenhaDTO = class
  private
    FSenha: string;
    FConfirmarSenha: string;
  public
    property Senha: string read FSenha write FSenha;
    property ConfirmarSenha: string read FConfirmarSenha write FConfirmarSenha;
  end;

implementation

end.
