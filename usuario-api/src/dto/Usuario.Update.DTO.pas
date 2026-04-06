unit Usuario.Update.DTO;

interface

type
  TUsuarioUpdateDTO = class
  private
    FLogin: string;
    FNome: string;
    FEmail: string;
    FAtivo: string;
  public
    property Login: string read FLogin write FLogin;
    property Nome: string read FNome write FNome;
    property Email: string read FEmail write FEmail;
    property Ativo: string read FAtivo write FAtivo;
  end;

implementation

end.
