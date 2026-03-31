unit Usuario.DTO;

interface

type
  TUsuarioCreateDTO = class
  private
    FLogin: string;
    FNome: string;
    FEmail: string;
    FSenha: string;
  public
    property Login: string read FLogin write FLogin;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property Senha: string read FSenha write FSenha;
  end;

implementation

end.
