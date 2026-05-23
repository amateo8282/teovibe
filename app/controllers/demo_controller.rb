# React 마운트 패턴 및 ViewComponent 검증용 데모 컨트롤러
class DemoController < ApplicationController
  allow_unauthenticated_access
  def react; end
end
