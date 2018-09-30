PREFIX  acl:  <http://www.w3.org/ns/auth/acl#>
PREFIX  def: <../ns/default#>

INSERT DATA
{
  GRAPH <graphs/a86ce4fa-0197-4118-878e-32ea2d695878>
  {
    <acl/authorizations/public#this> acl:accessToClass def:Container, def:Item, def:File .
  }
}